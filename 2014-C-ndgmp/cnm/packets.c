#include <stdlib.h>
#include <string.h>

#include "config.h"
#include "packets.h"

void* Packet00_Login_New(char* username, char* password) {
	int usernameLength = strlen(username) + 1;
	int passwordLength = strlen(password) + 1;
	Packet00_LoginHeader* packet = (Packet00_LoginHeader*)malloc(sizeof(Packet00_LoginHeader) + usernameLength + passwordLength);
	void* packetEnd = (void*)packet + sizeof(Packet00_LoginHeader);

	packet->packetID = 0x00; // Login id
	packet->protocol = htons(PROTOCOL); // Protocol
	memcpy(packetEnd, username, usernameLength); // Copy in username to packet
	memcpy(packetEnd + usernameLength, password, passwordLength); // Copy in password to packet

	return (void*)packet;
}
