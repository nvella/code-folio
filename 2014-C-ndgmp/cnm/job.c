#include <stdlib.h>

#include "job.h"
#include "golworld.h"

void Job_Delete(Job* job) {
	GOLWorld_Delete(job->world);
	free(job);
}
