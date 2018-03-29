#ifndef _GOLWORLD_H
#define _GOLWORLD_H

#define LIFE_LIVE 6		// 6 makes offset 1&2 == 1.
#define LIFE_BORN 4		// 4 makes offset 2 == 1. offsets are zero based so this will make cells born on 3
#define CHUNK_SIZE 256		// Size of each chunk

#define DIR_TRANS {8, 7, 6, 5, 4, 3, 2, 1, 0}

typedef struct GOLWorld GOLWorld;
typedef struct GOLChunk GOLChunk;
typedef struct GOLSpecialOp GOLSpecialOp;

struct GOLWorld {
	GOLChunk* first; 	 // first chunk. world uses linked list for storage
	unsigned char liveRules; // each bit specifies how many neighbours are required
				 // for life. bit 0: 1 neighbour, 1: 2 neigbours, etc...
	unsigned char bornRules; // same as above, but for cells being born.
	int ticks;		 // amount of ticks ran on world.
};

struct GOLChunk {
	int x, y, cellsAlive, cellsPending;
	char data[CHUNK_SIZE * CHUNK_SIZE];
	char pendingData[CHUNK_SIZE * CHUNK_SIZE];

	GOLChunk* next;		 // next chunk in linked list
};

struct GOLSpecialOp {
	int x, y;
	GOLSpecialOp* next;
};

GOLWorld* GOLWorld_New(unsigned char liveRules, unsigned char bornRules);
void	  GOLWorld_Delete(GOLWorld* world);
GOLWorld* GOLWorld_Duplicate(GOLWorld* original);
int	  GOLWorld_Compare(GOLWorld* world1, GOLWorld* world2);
GOLWorld* GOLWorld_GetCentered(GOLWorld* world);

void	  GOLWorld_Tick(GOLWorld* world);
void	  GOLWorld_AddChunk(GOLWorld* world, GOLChunk* chunk);

GOLChunk*  GOLChunk_New(int x, int y);
inline int GOLChunk_GetNeighbours(GOLWorld* world, GOLChunk* chunk, int x, int y);

void	  GOLWorld_CellOn(GOLWorld* world, long x, long y);

#endif
