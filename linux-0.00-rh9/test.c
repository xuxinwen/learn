
#define BIT_GRANULARITY 0x80000000000000
#define BIT_BIG 0x40000000000000
#define BIT_DEFAULT 0x40000000000000
#define BIT_AVAILABLE 0x10000000000000
#define BIT_PRESENT 0x800000000000
#define BIT_EXPAND_DOWN 0x40000000000
#define BIT_WRITABLE 0x20000000000
#define BIT_ACCESSED 0x10000000000
#define BIT_READABLE 0x20000000000
#define BIT_CONFORMING 0x40000000000

#define BIT_TYPE4 0x1000

#define descriptor(base, limit, dpl, fields) (\
    (((long long)(base) & 0xff000000) << 32) | \
    (((long long)(base) & 0x00ff0000) << 16) | \
    (((long long)(base) & 0x0000ffff) << 16) | \
    ((long long)(limit) & 0x0000ffff) | \
    ((long long)(limit) & 0xf0000) << 32 | \
    (long long)fields \
) 

#include <stdio.h>

int main() {
//0x00 c 0 9 a 00 000007ff
    long long l = descriptor(
        0, 0xfffff, 0, 
        (BIT_GRANULARITY | BIT_BIG | BIT_PRESENT | BIT_TYPE4)
    );

    printf("%#018llx\n", l);

    return 0;
}