#include "specmath.h"

int smod(int a, int b) {
	if(b < 0) //you can check for b == 0 separately and do what you want
		return smod(-a, -b);
	int ret = a % b;
	if(ret < 0)
		ret+=b;
	return ret;
}
