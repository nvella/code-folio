#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "chatbot.h"
#include "brain.h"

int getLine(char* prompt, char* buffer, size_t bufferSize) {
  if(prompt != NULL) {
    printf("%s", prompt);
    fflush(stdout);
  }
  if(fgets(buffer, bufferSize, stdin) == NULL) return 1;
  if(buffer[strlen(buffer) - 1] != '\n') {
    int extra = 0;
    char ch;
    while(((ch = getchar()) != '\n') && (ch != EOF)) extra = 1;
    if(extra == 1) { return 2; } else { return 0; } // too long, else ok
  }
  
  buffer[strlen(buffer) - 1] = '\0';
  return 0;
}

BrainHeader BrainHeader_New() {
  BrainHeader bh;
  bh.magic[0] = 'C'; bh.magic[1] = 'B'; bh.magic[2] = 'B';
  bh.version = BRAIN_VERSION;
  bh.entries = 0;
  bh.firstPhrase = NULL; 
  
  return bh;
}

void BrainPhrase_Init(BrainPhrase* bp) {
  bp->keywordArray = NULL; // Make null
  bp->text = NULL; // Make null
  bp->parent = MAX_INT;
  bp->rating = 0; // Max rating
  bp->id = 0;
}

void BrainPhrase_FreeLinkedList(BrainPhrase* bp) {
  if(bp->nextPhrase != NULL) BrainPhrase_FreeLinkedList(bp->nextPhrase);
  free(bp);
}

void BrainPhrase_AppendKeyword(BrainPhrase* brainPhrase, char* keyword) {
  // If keyword array exists then
  //  Find keyword array size in bytes.  
  //  Allocate size+keywordSize+1 bytes
  //  Copy keyword array into new position in memory
  //  Set last byte to 0x01
  //  Copy keyword onto end
  //  Set end byte to 0x00
  int keywordArraySize = 0;
  if(brainPhrase->keywordArray != NULL) {
    char* keywordArrayPosition = brainPhrase->keywordArray;
    while(*keywordArrayPosition != 0x00) {
      keywordArraySize++; 
      keywordArrayPosition++;
    }
  }
  
  char* newKeywordArray = (char*)malloc(keywordArraySize + strlen(keyword) + 1);
  if(keywordArraySize != 0) {
    memcpy((void*)newKeywordArray, (void*)brainPhrase->keywordArray, keywordArraySize);
    newKeywordArray[keywordArraySize] = 0x01;
  }
  strcpy(newKeywordArray + keywordArraySize + 1, keyword);
  
  brainPhrase->keywordArray = newKeywordArray;
}

BrainPhrase* BrainPhrase_GetLastPhrase(BrainPhrase* bp) {
  while(1) { // Traverse up linked list
    if(bp->nextPhrase != NULL) {
      bp = bp->nextPhrase;
    } else {
      break;
    }
  }
  return bp;
}

void Brain_InsertPhrase(BrainHeader* brainHeader, BrainPhrase* brainPhrase) {
  BrainPhrase_GetLastPhrase(brainHeader->firstPhrase)->nextPhrase = brainPhrase;
  brainHeader->entries++;
}

int Brain_RemovePhrase(BrainHeader* brainHeader, unsigned int phraseID) {
  BrainPhrase* phrase = brainHeader->firstPhrase;
  
  // Do some special handling for the first phrase in the database
  if(phrase->id == phraseID) {
    if(phrase->nextPhrase != NULL) {
      phrase->nextPhrase = phrase->nextPhrase->nextPhrase;
    } else {
      phrase->nextPhrase = NULL;      
    }
    brainHeader->entries--; 
    free(phrase->nextPhrase); 
  } else {
    while(1) { 
      if(phrase->nextPhrase != NULL && phrase->nextPhrase->id == phraseID) {
        phrase->nextPhrase = phrase->nextPhrase->nextPhrase; // Will equal NULL if there is no next phrase after element to be deleted anyway
        free(phrase->nextPhrase);
        brainHeader->entries--;
        break;
      } else {
        if(phrase->nextPhrase == NULL) return 1;
        phrase = phrase->nextPhrase;
      }
    }
    
  }
}

BrainPhrase* Brain_FindPhrase(BrainHeader* brainHeader, unsigned int phraseID) {
  BrainPhrase* bp = brainHeader->firstPhrase;
  
  while(bp != NULL) {
    if(bp->id == phraseID) return bp;
    bp = bp->nextPhrase;
  }

  return NULL;
}

int Brain_LoadFromDisk(BrainHeader* brainHeader, char* filename) {
  FILE* bf = fopen(filename, "rb");
  if(fgetc(bf) != 'C') return 1; // Magic
  if(fgetc(bf) != 'B') return 1; // Number
  if(fgetc(bf) != 'B') return 1; // Check
  
  fread(&(brainHeader->version), sizeof(brainHeader->version), 1, bf); // version
  if(brainHeader->version != BRAIN_VERSION) return 1;

  fread(&(brainHeader->entries), sizeof(brainHeader->entries), 1, bf); // entries
  
  BrainPhrase* lastPhrase;
  
  for(unsigned int i = 0; i < brainHeader->entries; i++) {
    BrainPhrase* bp = (BrainPhrase*)malloc(sizeof(BrainPhrase));
    BrainPhrase_Init(bp);
    
    int startPos = ftell(bf);
    int keywordArrayLength = 0;
    while(1) {
      if(fgetc(bf) == 0x00) break;
      keywordArrayLength++;
    }
    keywordArrayLength++; // Take into account the NULL termination
        
    bp->keywordArray = (char*)malloc(keywordArrayLength);
    fseek(bf, startPos, SEEK_SET);
    fread(bp->keywordArray, 1, keywordArrayLength, bf);
    
    startPos = ftell(bf);
    int textLength = 0;
    while(1) {
      if(fgetc(bf) == 0x00) break;
      textLength++;
    }
    textLength++; // add one more to count null.
    
    bp->text = (char*)malloc(textLength);
    fseek(bf, startPos, SEEK_SET);
    fread(bp->text, 1, textLength, bf);

    fread(&(bp->parent), sizeof(bp->parent), 1, bf); // parent
    fread(&(bp->rating), sizeof(bp->rating), 1, bf); // rating
    bp->id = i;
    printf("ID %i TEXT %s\n", i, bp->text);
    if(brainHeader->firstPhrase == NULL) {
      brainHeader->firstPhrase = bp;
    } else {
      lastPhrase->nextPhrase = bp;      
    }
    lastPhrase = bp;    
  }
  
  fclose(bf);
  return 0;
}

int Brain_SaveToDisk(BrainHeader* brainHeader, char* filename) {
  FILE* bf = fopen(filename, "wb");
  /* Header */
  fwrite(brainHeader->magic, 1, 3, bf);
  fwrite(&(brainHeader->version), sizeof(brainHeader->version), 1, bf);
  fwrite(&(brainHeader->entries), sizeof(brainHeader->entries), 1, bf);
  
  /* Phrases */
  for(unsigned int i = 0; i < brainHeader->entries; i++) { // For loop to write in order
    BrainPhrase* bp = Brain_FindPhrase(brainHeader, i);    
    if(bp != NULL) {
      fwrite(bp->keywordArray, 1, strlen(bp->keywordArray) + 1, bf); // Write keyword array
      fwrite(bp->text, 1, strlen(bp->text) + 1, bf); // Write actual phrase    
      fwrite(&(bp->parent), sizeof(bp->parent), 1, bf); // Write parent id
      fwrite(&(bp->rating), sizeof(bp->rating), 1, bf); // Wrtie rating
    }
  }
  
  fclose(bf);
  
  return 0;
}

int Brain_FindDegreesOfSeperation(BrainHeader* brainHeader, BrainPhrase* higher, BrainPhrase* lower){
  int sep = 0;

  while(lower != NULL || lower->id != higher->id) {
    if(lower->parent == MAX_INT) return 0;
    lower = Brain_FindPhrase(brainHeader, lower->parent);
    sep++;
  }
  
  return sep;
}

BrainPhrase* Brain_FindReplies(BrainHeader* brainHeader, unsigned int phraseID) {
  BrainPhrase* replyTree = NULL;
  BrainPhrase* bp = brainHeader->firstPhrase;

  while(bp != NULL) {
    if(bp->parent == phraseID) {
      BrainPhrase* newPhrase = (BrainPhrase*)malloc(sizeof(BrainPhrase));
      memcpy(newPhrase, bp, sizeof(BrainPhrase));
      newPhrase->nextPhrase = NULL;
           
      if(replyTree == NULL) {
        replyTree = newPhrase;
      } else {
        BrainPhrase* p = BrainPhrase_GetLastPhrase(replyTree)->nextPhrase = newPhrase;
      }
    }
    bp = bp->nextPhrase;
  }
  
  return replyTree;  
}

int main(int argc, char** argv) {
  printf("%s version %s\n", NAME, VERSION);
  if(argc < MIN_ARGS + 1) {
    printf("usage: %s BRAINFILE", argv[0]);
    return 1;
  }
  
  BrainHeader brain = BrainHeader_New();
  Brain_LoadFromDisk(&brain, argv[1]);
  printf("Phrases in brain: %i\n", brain.entries);
  
/*  while(1) { // Main loop
    char buffer[4096];
    getLine("> ", buffer, sizeof(buffer));
    printf("%s\n", buffer);
  }*/
  
  BrainPhrase* rp = Brain_FindReplies(&brain, 54);
  while(rp != NULL) {
    printf("P: %i ID: %i: %s\n", rp->parent, rp->id, rp->text);
    rp = rp->nextPhrase;
  }
    
  return 0;
}
