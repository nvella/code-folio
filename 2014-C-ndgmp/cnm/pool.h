#include <sys/socket.h>
#include <arpa/inet.h>

#ifndef _POOL_H
#define _POOL_H

// #define PLACE_OFFSET 64 // Give the patterns a little bit of buffer so they don't make new chunks

#include "job.h"

typedef struct Pool Pool;

struct Pool {
	int sock; // Socket file descriptor
	struct sockaddr_in poolServer; // Socket struct for pool server

	unsigned int maxGenerations; // How long a grid should run for before requesting another.
	char* username;
	char* password;
	char rules[2];

	pthread_mutex_t mutex;
};

Pool* Pool_New(char* address, unsigned short port, char* username, char* password);
int   Pool_Connect(Pool* pool);

Job*  Pool_RequestJobBatch(Pool* pool);
void  Pool_CommitJobBatch(Pool* pool, Job* jobBatch);
#endif
