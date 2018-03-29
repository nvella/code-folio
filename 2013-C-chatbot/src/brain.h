#define BRAIN_MAGIC 'CBB'
#define BRAIN_VERSION 1

struct BrainHeader {
  char magic[3];
  unsigned short version;
  unsigned long entries;
  
  struct BrainPhrase* firstPhrase;
};

struct BrainPhrase {
  char* keywordArray; // seperated by 0x01 and terminated by 0x00
  char* text;
  unsigned int parent;
  unsigned short rating;  
  unsigned int id;
  
  struct BrainPhrase* nextPhrase;
};

typedef struct BrainHeader BrainHeader;
typedef struct BrainPhrase BrainPhrase;

