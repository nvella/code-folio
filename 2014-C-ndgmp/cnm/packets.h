#ifndef _PACKETS_H
#define _PACKETS_H

typedef struct Packet00_LoginHeader Packet00_LoginHeader;

struct __attribute__((__packed__)) Packet00_LoginHeader { // Since login includes two null-terminated strings, we cannot
				// use a struct for the whole packet
	unsigned char packetID;
	unsigned short protocol;
};

void* Packet00_Login_New(char* username, char* password);

#endif
