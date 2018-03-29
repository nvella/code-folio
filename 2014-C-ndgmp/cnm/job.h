#ifndef _JOB_H
#define _JOB_H

#include "golworld.h"

#define JOB_UNFINISHED 2
#define JOB_OSCILLATES 3
#define JOB_STILL_LIFE 4
#define JOB_SPACESHIP  5

typedef struct Job Job;

struct Job {
	unsigned long id;
	unsigned long gridWidth;
	unsigned long gridHeight;
	GOLWorld* world;

	unsigned char state;
	unsigned int oscillationStart;
	unsigned int oscillationEnd;

	unsigned int msSpent; // Microseconds spent on job

	Job* next;
};

void Job_Delete(Job* job);

#endif
