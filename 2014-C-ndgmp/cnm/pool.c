#include <stdlib.h>      // For malloc
#include <sys/socket.h>  // For sockets
#include <arpa/inet.h>   // For sockets
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <stdio.h>
#include <errno.h>

#include "pool.h"
#include "golworld.h"
#include "job.h"
#include "packets.h"
#include "sys.h"

Pool* Pool_New(char* address, unsigned short port, char* username, char* password) {
	Pool* pool = (Pool*)malloc(sizeof(Pool));
	memset(&pool->poolServer, 0, sizeof(pool->poolServer));

	pool->poolServer.sin_family = AF_INET; // Setup socket
	pool->poolServer.sin_addr.s_addr = inet_addr(address);
	pool->poolServer.sin_port = htons(port);

	pool->sock = -1;
	pool->maxGenerations = 0; // To be set later
	pool->username = username; // NOTE Since we are not copying, only storing pointers,
	pool->password = password; //	   we must not dereference these pointers anywhere!

	pool->rules[0] = 0x00;
	pool->rules[1] = 0x00;

	pthread_mutex_init(&pool->mutex, NULL);

	return pool;
}

int Pool_Connect(Pool* pool) {
	// Initialize socket
	pool->sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	if(pool->sock < 0) return 1;
	// Attempt to connect to pool server.
	if(connect(pool->sock, (struct sockaddr*)&pool->poolServer, sizeof(pool->poolServer)) < 0) {
//		printf("errno: %s\n", strerror(errno));
		return 2;
	}

	// Send the login packet.
	void* packet = Packet00_Login_New(pool->username, pool->password); // Create the packet
	// Send the data
	int packetSize = sizeof(Packet00_LoginHeader) + strlen(pool->username) + strlen(pool->password) + 2;
	if(send(pool->sock, packet, packetSize, 0) != packetSize) {
		free(packet); // Free the packet memory
		close(pool->sock); // Close the socket
		return 3;
	}
	free(packet); // Free the packet memory

	// Attempt to recieve OK packet
	unsigned char returnPacketID = 255;
	if(recv(pool->sock, &returnPacketID, 1, MSG_WAITALL) != 1) {
		close(pool->sock); // Close socket
		return 4;
	}

	// Check if packet id is 0x04
	if(returnPacketID != 0x04) {
		close(pool->sock); // Close socket
		return 5;
	}

	// Receive max generations
	if(recv(pool->sock, &pool->maxGenerations, 4, MSG_WAITALL) != 4) {
		close(pool->sock); // Close socket
		return 6;
	}
	
	// Convert maxGenerations (int) to host order.
	pool->maxGenerations = ntohl(pool->maxGenerations);
	
	// Receive rules
	if(recv(pool->sock, &pool->rules, 2, MSG_WAITALL) != 2) {
		close(pool->sock); // Close socket
		return 7;
	}


	return 0;
}

// Returns linked list of jobs for worker to process
// TODO obey network order
Job* Pool_RequestJobBatch(Pool* pool) {
	Job* jobBatch = malloc(sizeof(Job));
	Job* currentJob = jobBatch;
	pthread_mutex_lock(&pool->mutex);
	unsigned char packetID = 0x02;
	if(send(pool->sock, &packetID, 1, 0) != 1) Sys_RaiseError("pool: couldn't send request packet.\n");
	packetID = 0x99;
	if(recv(pool->sock, &packetID, 1, MSG_WAITALL) != 1) Sys_RaiseError("pool: couldn't receive packet id\n");
	if(packetID != 0x03) Sys_RaiseError("pool: expected packet id 0x03, got something else\n");

	unsigned short jobsInPacket = 0;
	if(recv(pool->sock, &jobsInPacket, 2, MSG_WAITALL) != 2) Sys_RaiseError("pool: couldn't receive jobs in packet.\n");
	
	// Network order
	jobsInPacket = ntohs(jobsInPacket);

	int gridDataLength;
	for(int i = 0; i < jobsInPacket; i++) {
		// Receive job data
		if(recv(pool->sock, &currentJob->id, 8, MSG_WAITALL) != 8) Sys_RaiseError("pool: error receiving new job. (0)\n");
		if(recv(pool->sock, &currentJob->gridWidth, 8, MSG_WAITALL) != 8) Sys_RaiseError("pool: error receiving new job. (1)\n");
		if(recv(pool->sock, &currentJob->gridHeight, 8, MSG_WAITALL) != 8) Sys_RaiseError("pool: error receiving new job. (2)\n");
		if(recv(pool->sock, &gridDataLength, 4, MSG_WAITALL) != 4) Sys_RaiseError("pool: error receiving new job. (3)\n");

		currentJob->state = JOB_UNFINISHED; // Set the job state to unfinished

		char* gridData = (char*)malloc(gridDataLength);
		if(recv(pool->sock, gridData, gridDataLength, MSG_WAITALL) != gridDataLength) Sys_RaiseError("pool: couldn't download grid data from pool.\n");
		// Turn grid data into GOLWorld
		currentJob->world = GOLWorld_New(pool->rules[0], pool->rules[1]);
		for(int y = 0; y < currentJob->gridHeight; y++) {
			for(int x = 0; x < currentJob->gridWidth; x++) {
				if(gridData[x + (y * currentJob->gridWidth)] == 0x01) GOLWorld_CellOn(currentJob->world, x, y); // CONSIDER enabling PLACE_OFFSET again
			}
		}
		// Free grid data pointer
		free(gridData);

		if(i < jobsInPacket - 1) {
			currentJob->next = malloc(sizeof(Job));
			currentJob = currentJob->next;
		} else {
			currentJob->next = NULL; // Terminate the linked list.
		}
	}

	pthread_mutex_unlock(&pool->mutex);
	return jobBatch;
}

void Pool_CommitJobBatch(Pool* pool, Job* jobBatch) {
	// First, count jobs in packet and size of buffer to create
	short jobsInPacket = 0;
	int bufferSize = 3; // Includes ID and short of packet
	Job* job = jobBatch;
	while(job != NULL) {
		jobsInPacket++;
		bufferSize += 17; // Includes base packet
		if(job->state == JOB_OSCILLATES || job->state == JOB_SPACESHIP) bufferSize += 8;
			// Includes the 2 ints that state oscillation start and end
		job = job->next;
	}
	char* buffer = malloc(bufferSize); // Create the buffer
	memset(buffer, 0, bufferSize); // Clear the buffer
	buffer[0] = 0x06; // Job Done packet id
	memcpy(buffer + 1, &jobsInPacket, 2); // Copy in jobs-in-packet value
	job = jobBatch;
	int i = 3;
	while(job != NULL) {
		memcpy(buffer + i, &job->id, 8); // long: job id
		memcpy(buffer + i + 8, &job->state, 1); // byte: state of grid
		memcpy(buffer + i + 9, &job->world->ticks, 4); // int: generations ran
		memcpy(buffer + i + 13, &job->msSpent, 4); // int: microseconds spent on job
		i += 17; // Increment counter
		if(job->state == JOB_OSCILLATES || job->state == JOB_SPACESHIP) {
			memcpy(buffer + i, &job->oscillationStart, 4); // int: start of oscillation
			memcpy(buffer + i + 4, &job->oscillationEnd, 4); // int: end of oscillation
			i += 8; // Increment counter for extra data
		}
		job = job->next;
	}

	pthread_mutex_lock(&pool->mutex); // Lock the mutex
	// Send the job over the network
	if(send(pool->sock, buffer, bufferSize, MSG_WAITALL) != bufferSize) Sys_RaiseError("pool: failed to commit job.\n");
	pthread_mutex_unlock(&pool->mutex); // Unlock the mutex
	free(buffer); // Free the buffer
}
