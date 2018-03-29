// C NDGMP Miner

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>

#include <sys/socket.h>
#include <arpa/inet.h>

#include <time.h>

#include "config.h"
#include "worker.h"
#include "pool.h"
#include "job.h"
#include "golworld.h"

int Running;

int main(int argc, char** argv) {
	printf("%s version %s\n", NAME, VERSION);
	printf("protocol version %i\n", PROTOCOL);

	if(argc < 6) {
		printf("usage: %s THREADS POOL_ADDRESS POOL_PORT USERNAME PASSWORD\n", argv[0]);
		printf("if no password supplied then use user 'anon' with password 'password'\n");
		return 1;
	}

	// Attempt to connect to pool and authenticate
	printf("attempting to connect to pool...\n");
	Pool* pool = Pool_New(argv[2], atoi(argv[3]), argv[4], argv[5]);
	int ok = Pool_Connect(pool);
	if(ok != 0) {
		printf("error connecting to pool.\n  id: %i\n errno: %s\n", ok, strerror(errno));
		return 1;
	}

	printf("connected.\n");
	printf("max generations: %i rulemasks: %i %i\n", pool->maxGenerations, pool->rules[0], pool->rules[1]);
/*
	GOLWorld* orig = GOLWorld_New(LIFE_LIVE, LIFE_BORN);
	GOLWorld* off = GOLWorld_New(LIFE_LIVE, LIFE_BORN);

	GOLWorld_CellOn(orig, 0, 0);
	GOLWorld_CellOn(orig, 1, 0);
	GOLWorld_CellOn(orig, 2, 0);
	GOLWorld_CellOn(orig, 2, 1);
	GOLWorld_CellOn(orig, 1, 2);

	GOLWorld_CellOn(off, 5, 5);
	GOLWorld_CellOn(off, 6, 5);
	GOLWorld_CellOn(off, 7, 5);
	GOLWorld_CellOn(off, 7, 6);
	GOLWorld_CellOn(off, 6, 7);

	GOLWorld_Tick(off);
	GOLWorld_Tick(off);
	GOLWorld_Tick(off);
	GOLWorld_Tick(off);

	GOLWorld* cent = GOLWorld_GetCentered(off);

	printf("results: %i\n", GOLWorld_Compare(orig, cent));*/

	// Create workers
	int workerCount = atoi(argv[1]);
	Worker* workers[workerCount];
	for(int i = 0; i < workerCount; i++) workers[i] = Worker_New(i, pool, &Running);

	// Start workers.
	printf("starting workers...\n");
	Running = 1; // Set running to true

	for(int i = 0; i < workerCount; i++) {
		printf("  starting worker %i...\n", i);
		pthread_create(&(workers[i]->thread), NULL, Worker_Run, workers[i]);
	}
	for(int i = 0; i < workerCount; i++) pthread_join(workers[i]->thread, NULL);

	return 0;
}
