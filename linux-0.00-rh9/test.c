#include <stdio.h>

#define DEBUG
#include "i386.h"


int main() {
    long long l = _descriptor(
        0xb8000, 0x2, PL0, 
        (BIT_TYPE_DATA | BIT_WRITABLE | BIT_GRANULARITY | BIT_BIG | BIT_PRESENT)
    );

    printf("%#018llx\n", l);

    return 0;
}