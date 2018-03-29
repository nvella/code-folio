#ifndef _WORKER_H
#define _WORKER_H

#include <pthread.h>

#include "pool.h"

typedef struct Worker Worker;

struct Worker {
	int id;
	Pool* pool;
	int* runningFlag;
	pthread_t thread; // Thread

	// TODO pointer to job batch
};

Worker* Worker_New(int id, Pool* pool, int* runningFlag);
void*	Worker_Run(void* ptr);

#endif
