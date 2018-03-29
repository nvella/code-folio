#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include "golworld.h"
#include "specmath.h"

GOLWorld* GOLWorld_New(unsigned char liveRules, unsigned char bornRules) {
	GOLWorld* world = (GOLWorld*)malloc(sizeof(GOLWorld));
	world->ticks = 0;
	world->liveRules = liveRules;
	world->bornRules = bornRules;
	world->first = NULL;
	return world;
}

GOLChunk* GOLChunk_New(int x, int y) {
	GOLChunk* chunk = (GOLChunk*)malloc(sizeof(GOLChunk));
	chunk->next = NULL;
	memset(&chunk->data, 0, CHUNK_SIZE * CHUNK_SIZE);
	memset(&chunk->pendingData, 0, CHUNK_SIZE * CHUNK_SIZE);
	chunk->cellsAlive = 0;
	chunk->cellsPending = 0;
	chunk->x = x;
	chunk->y = y;
	return chunk;
}

void GOLWorld_Tick(GOLWorld* world) {
	if(world->first == NULL) return; // algo will not function with no cells
	GOLChunk* chunk = world->first;
	GOLSpecialOp* specialOps = NULL;
	int neighbours = 0; // initialize variable up here

	while(chunk != NULL) {
		if(chunk->cellsAlive < 1) { // If chunk is empty, skip it to save time
			chunk = chunk->next;
			continue;
		}

		// Chunk is not empty, loop over every cell, alive or dead.
		for(int i = 0; i < CHUNK_SIZE * CHUNK_SIZE; i++) {
			int x = i % CHUNK_SIZE;
			int y = i / CHUNK_SIZE;
			if(chunk->data[i] == 0x00) continue; // skip because there is no cell

			// First, check if this cell should survive to the next round.

			neighbours = GOLChunk_GetNeighbours(world, chunk, x, y);
			if((world->liveRules & (int)pow(2, neighbours - 1)) != 0) {
				if(chunk->pendingData[i] == 0x00) {
					chunk->cellsPending++;
					chunk->pendingData[i] = 0x01;
				}
			}

			// Then check all the cell's neighbours for cells that should be born.

			for(int relX = -1; relX < 2; relX++) {
				for(int relY = -1; relY < 2; relY++) {
					int actualX = x + relX;
					int actualY = y + relY;
					neighbours = GOLChunk_GetNeighbours(world, chunk, actualX, actualY);
					if((world->bornRules & (int)pow(2, neighbours - 1)) != 0) {
						if(actualX >= 0 && actualX < CHUNK_SIZE && actualY >= 0 && actualY < CHUNK_SIZE) {
							// cell to be born is inside of chunk, nothing fancy here
							int pos = actualX + (actualY * CHUNK_SIZE);
							if(chunk->pendingData[pos] == 0x00) {
								chunk->cellsPending++;
								chunk->pendingData[pos] = 0x01;
							}
						} else {
							// cell to be born is outside of chunk, pass to cell on function
							int chunkX = chunk->x; // create chunk coords
							int chunkY = chunk->y;
							int pos = smod(actualX, CHUNK_SIZE) + (smod(actualY, CHUNK_SIZE) * CHUNK_SIZE);
							if(actualX < 0) { chunkX--; } else if(actualX >= CHUNK_SIZE) { chunkX++; }
							if(actualY < 0) { chunkY--; } else if(actualY >= CHUNK_SIZE) { chunkY++; }

							GOLChunk* travelChunk = world->first;
							int foundChunk = 0;
							while(travelChunk != NULL) {
								if(travelChunk->x == chunkX && travelChunk->y == chunkY) {
									foundChunk = 1;
									if(travelChunk->pendingData[pos] == 0x00) {
										travelChunk->cellsPending++;
										travelChunk->pendingData[pos] = 0x01;
										break; // Break out of search for chunk;
									}
								}
								travelChunk = travelChunk->next;
							}

							if(foundChunk == 0) { // Didn't find the chunk, make a special op to create the chunk.
								if(specialOps == NULL) {
									specialOps = (GOLSpecialOp*)malloc(sizeof(GOLSpecialOp));
									specialOps->next = NULL;
								} else {
									GOLSpecialOp* old = specialOps;
									specialOps = (GOLSpecialOp*)malloc(sizeof(GOLSpecialOp));
									specialOps->next = old;
								}
								specialOps->x = (chunkX * CHUNK_SIZE) + smod(actualX, CHUNK_SIZE);
								specialOps->y = (chunkY * CHUNK_SIZE) + smod(actualY, CHUNK_SIZE);
							}
						}
					}
				}
			}
		}
		chunk = chunk->next; // Advance to next chunk

	}

	// Move all cells pending into actual data, set cells pending to 0
	chunk = world->first;
	while(chunk != NULL) {
		chunk->cellsAlive = chunk->cellsPending;
		chunk->cellsPending = 0;
		memcpy(&chunk->data, &chunk->pendingData, CHUNK_SIZE * CHUNK_SIZE);
		memset(&chunk->pendingData, 0, CHUNK_SIZE * CHUNK_SIZE);
		chunk = chunk->next;
	}

	// Go through the special ops and apply those.
	while(specialOps != NULL) {
		int chunkFound = 0;
		GOLChunk* myChunk = world->first; // TODO rename this

		int chunkX = specialOps->x / CHUNK_SIZE;
		int chunkY = specialOps->y / CHUNK_SIZE;
		double fruitingX = specialOps->x;
		double fruitingY = specialOps->y; // FruitING WHHYY?

		if(specialOps->x < 0) {
			chunkX = floor(fruitingX / CHUNK_SIZE);
		}
		if(specialOps->y < 0) {
			chunkY = floor(fruitingY / CHUNK_SIZE);
		} 

		while(myChunk != NULL) {
			if(myChunk->x == chunkX && myChunk->y == chunkY) {
				int pos = smod(specialOps->x, CHUNK_SIZE) + (smod(specialOps->y, CHUNK_SIZE) * CHUNK_SIZE);
				if(myChunk->data[pos] == 0x00) {
					myChunk->cellsAlive++;
					myChunk->data[pos] = 0x01;
				}
				chunkFound = 1;
				break; // found special op location
			}
			myChunk = myChunk->next;
		}

		if(chunkFound == 0) { // a sutiable chunk for the cell was not found, make one
			GOLChunk* newChunk = GOLChunk_New(chunkX, chunkY);
			int pos = smod(specialOps->x, CHUNK_SIZE) + (smod(specialOps->y, CHUNK_SIZE) * CHUNK_SIZE);
			newChunk->cellsAlive = 1;
			newChunk->data[pos] = 0x01;
			GOLWorld_AddChunk(world, newChunk); // Add the new chunk
		}

		GOLSpecialOp* nextOp = specialOps->next;
		free(specialOps);
		specialOps = nextOp;
	}

	world->ticks++;

	return;
}

// Params
//	gol world
// 	chunk cell is in
//	x and y of cell relative to chunk

inline int GOLChunk_GetNeighbours(GOLWorld* world, GOLChunk* chunk, int x, int y) {
	int neighbours = 0;
	for(int relX = -1; relX < 2; relX++) {
		for(int relY = -1; relY < 2; relY++) {
			if(relX == 0 && relY == 0) continue; // don't count self
			int actualX = x + relX;
			int actualY = y + relY;
			if(actualX >= 0 && actualX < CHUNK_SIZE && actualY >= 0 && actualY < CHUNK_SIZE) {
				// cell is in chunk, preform normal lookup
				if(chunk->data[actualX + (actualY * CHUNK_SIZE)] != 0x00) neighbours++;
			} else {
				// cell isn't in chunk, search whole world for relative chunk
				int chunkX = chunk->x;
				int chunkY = chunk->y;
				int pos = smod(actualX, CHUNK_SIZE) + (smod(actualY, CHUNK_SIZE) * CHUNK_SIZE);
				if(actualX < 0) { chunkX--; } else if(actualX >= CHUNK_SIZE) { chunkX++; }
				if(actualY < 0) { chunkY--; } else if(actualY >= CHUNK_SIZE) { chunkY++; }
				GOLChunk* travelChunk = world->first;
				while(travelChunk != NULL) {
					if(travelChunk->cellsAlive > 0 && travelChunk->x == chunkX && travelChunk->y == chunkY) { // don't waste time searching in empty chunks
						if(travelChunk->data[pos] != 0x00) neighbours++;
						break;
					}
					travelChunk = travelChunk->next;
				}
			}
		}
	}
	return neighbours;
}

void GOLWorld_AddChunk(GOLWorld* world, GOLChunk* chunk) {
	GOLChunk* oldChunk = world->first;
	world->first = chunk;
	chunk->next = oldChunk;
}

void GOLWorld_CellOn(GOLWorld* world, long x, long y) {
	GOLChunk* chunk = world->first;
	int chunkX = x / CHUNK_SIZE;
	int chunkY = y / CHUNK_SIZE;
	double fruitingX = x;
	double fruitingY = y; // FruitING WHHYY?

	if(x < 0) {
		chunkX = floor(fruitingX / CHUNK_SIZE);
	}
	if(y < 0) {
		chunkY = floor(fruitingY / CHUNK_SIZE);
	}

	int relPos = smod(x, CHUNK_SIZE) + (smod(y, CHUNK_SIZE) * CHUNK_SIZE);
	while(chunk != NULL) {
		if(chunk->x == chunkX && chunk->y == chunk->y) {
			if(chunk->data[relPos] == 0x00) {
				chunk->data[relPos] = 0x01;
				chunk->cellsAlive++;
			}
			return;
		}
		chunk = chunk->next;
	}
	// No suitable chunk found, make a new one for it.
	GOLChunk* newChunk = GOLChunk_New(chunkX, chunkY);
	newChunk->data[relPos] = 0x01;
	newChunk->cellsAlive = 1;
	GOLWorld_AddChunk(world, newChunk);
}

int GOLWorld_Compare(GOLWorld* world1, GOLWorld* world2) {
	GOLChunk* chunk1 = world1->first;
	while(chunk1 != NULL) {
		int foundChunk = 0;
		GOLChunk* loopChunk = world2->first;
		while(loopChunk != NULL) {
			if(chunk1->x == loopChunk->x && chunk1->y == loopChunk->y) {
				if(chunk1->cellsAlive == loopChunk->cellsAlive) {
					if(memcmp(&chunk1->data, &loopChunk->data, CHUNK_SIZE * CHUNK_SIZE) != 0) return 0; // Cells not the same
					foundChunk = 1;
					break; // This chunk is the same, break out of the search (there only exists one chunk at these coords) and look at the next chunk
				} else {
					return 0; // Cells not the same
				}
			}
			loopChunk = loopChunk->next;
		}
		if(foundChunk == 0 && chunk1->cellsAlive > 0) return 0; // Could not find chunk with these coords, cells must not exist in other world
		chunk1 = chunk1->next;
	}

	GOLChunk* chunk2 = world2->first;
	while(chunk2 != NULL) {
		int foundChunk = 0;
		GOLChunk* loopChunk = world1->first;
		while(loopChunk != NULL) {
			if(chunk2->x == loopChunk->x && chunk2->y == loopChunk->y) {
				if(chunk2->cellsAlive == loopChunk->cellsAlive) {
					if(memcmp(&chunk2->data, &loopChunk->data, CHUNK_SIZE * CHUNK_SIZE) != 0) return 0; // Cells not the same
					foundChunk = 1;
					break; // This chunk is the same, break out of the search (there only exists one chunk at these coords) and look at the next chunk
				} else {
					return 0; // Cells not the same
				}
			}
			loopChunk = loopChunk->next;
		}
		if(foundChunk == 0 && chunk2->cellsAlive > 0) return 0; // Could not find chunk with these coords, cells must not exist in other world
		chunk2 = chunk2->next;
	}

	return 1; // Compared sucsessfully
}

GOLWorld* GOLWorld_Duplicate(GOLWorld* original) {
	GOLWorld* world = GOLWorld_New(original->liveRules, original->bornRules);
	world->ticks = original->ticks;
	GOLChunk* chunk = original->first;
	while(chunk != NULL) {
		GOLChunk* oldChunk = world->first;
		world->first = (GOLChunk*)malloc(sizeof(GOLChunk));
		memcpy(world->first, chunk, sizeof(GOLChunk));
		world->first->next = oldChunk;
		chunk = chunk->next;
	}
	return world;
}

GOLWorld* GOLWorld_GetCentered(GOLWorld* world) {
	// First, find the lowest x and y
	int firstPos = 0;
	long lowestX = 0;
	long lowestY = 0;
	GOLChunk* chunk = world->first;
	while(chunk != NULL) {
		if(chunk->cellsAlive > 0) {
			for(int i = 0; i < CHUNK_SIZE * CHUNK_SIZE; i++) {
				if(chunk->data[i] != 0x00) {
					int x = (chunk->x * CHUNK_SIZE) + (i % CHUNK_SIZE);
					int y = (chunk->y * CHUNK_SIZE) + (i / CHUNK_SIZE);
					if(firstPos == 0) {
						firstPos = 1;
						lowestX = x;
						lowestY = y;
					} else {
						if(x < lowestX) lowestX = x;
						if(y < lowestY) lowestY = y;
					}
				}
			}
		}
		chunk = chunk->next;
	}

	// Now apply that offset to a new world.
	GOLWorld* newWorld = GOLWorld_New(world->liveRules, world->bornRules);
	chunk = world->first; // Iterate over all the cells again
	while(chunk != NULL) {
		if(chunk->cellsAlive > 0) {
			for(int i = 0; i < CHUNK_SIZE * CHUNK_SIZE; i++) {
				if(chunk->data[i] != 0x00) {
					int x = (chunk->x * CHUNK_SIZE) + (i % CHUNK_SIZE);
					int y = (chunk->y * CHUNK_SIZE) + (i / CHUNK_SIZE);
					GOLWorld_CellOn(newWorld, x - lowestX, y - lowestY);
				}
			}
		}
		chunk = chunk->next;
	}
	// Return the new, centered world.
	return newWorld;
}

void GOLWorld_Delete(GOLWorld* world) {
	GOLChunk* chunk = world->first;
	free(world);
	while(chunk != NULL) {
		GOLChunk* nextChunk = chunk->next;
		free(chunk);
		chunk = nextChunk;
	}
}
