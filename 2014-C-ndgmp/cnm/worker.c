#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

#include "worker.h"
#include "pool.h"
#include "job.h"

Worker* Worker_New(int id, Pool* pool, int* runningFlag) {
	Worker* worker = (Worker*)malloc(sizeof(Worker));
	worker->id = id;
	worker->pool = pool;
	worker->runningFlag = runningFlag;
	return worker;
}

void* Worker_Run(void* ptr) {
	Worker* worker = (Worker*)ptr;
	Job* jobBatch = NULL;
	Job* job = NULL;
	clock_t startTime;
	while(*(worker->runningFlag)) {
		// Do thread work here!
		jobBatch = Pool_RequestJobBatch(worker->pool);
		job = jobBatch;
		while(job != NULL) {
			GOLWorld* states[worker->pool->maxGenerations + 1];
			startTime = clock(); // Get the start time
			states[0] = GOLWorld_Duplicate(job->world);
			for(int i = 1; i <= worker->pool->maxGenerations; i++) states[i] = NULL;
			for(int i = 1; i <= worker->pool->maxGenerations; i++) {
				// Tick world and do computations
				GOLWorld_Tick(job->world);
				if(GOLWorld_Compare(job->world, states[0]) == 1) {
					if(i == 1) {
						job->state = JOB_STILL_LIFE;
					} else {
						job->state = JOB_OSCILLATES;
						job->oscillationStart = 0;
						job->oscillationEnd = i; // Set oscillation start and end parameters
					}

					break;
				}

				// Check for gliders
				GOLWorld* centeredWorld = GOLWorld_GetCentered(job->world);
				if(GOLWorld_Compare(centeredWorld, states[0]) == 1) {
					GOLWorld_Delete(centeredWorld); // Free up the extra, centered world
					job->state = JOB_SPACESHIP; // Found a spaceship
					job->oscillationStart = 0;
					job->oscillationEnd = i;
					break;
				}
				GOLWorld_Delete(centeredWorld);
			}

			// Delete all the states
			for(int i = 0; i <= worker->pool->maxGenerations; i++) {
				if(states[i] != NULL) GOLWorld_Delete(states[i]);
			}
			job->msSpent = (int)((((float)(clock() - startTime)) / CLOCKS_PER_SEC) * 1000000); // Microseconds spent
			job = job->next;
		}
		// Commit jobs to pool
		Pool_CommitJobBatch(worker->pool, jobBatch);
		// Delete job batch
		job = jobBatch;
		while(job != NULL) {
			Job* nextJob = job->next;
			Job_Delete(job);
			job = nextJob;
		}
	}

	return NULL;
}
