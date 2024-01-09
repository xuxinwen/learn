#ifdef DEBUG
#define LONG_LONG (long long)
#else
#define LONG_LONG 
#endif

#define PL0 0b00
#define PL3 0b11
#define LDT_TI 0b100
#define GDT_TI 0b000

#define _selector(index, ti, rpl) ((index) << 3 | (ti) | (rpl))

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

#define BIT_TYPE_DATA (LONG_LONG 0b10 << 43)
#define BIT_TYPE_EXE (LONG_LONG 0b11 << 43)
#define BIT_BUSY (LONG_LONG 0b1 << 41) 
#define BIT_386TSS (LONG_LONG 0b1001 << 40) 
#define BIT_TYPE_LDT (LONG_LONG 0B10 << 40)

#define _descriptor(base, limit, dpl, fields) (\
    ((LONG_LONG(base) & 0xff000000) << 32) | \
    ((LONG_LONG(base) & 0x00ff0000) << 16) | \
    ((LONG_LONG(base) & 0x0000ffff) << 16) | \
    (LONG_LONG(limit) & 0x0000ffff) | \
    (LONG_LONG(limit) & 0xf0000) << 32 | \
    LONG_LONG(fields) \
) 

#define def_descriptor_64kbase(base, limit, dpl, fields) \
    .word (LONG_LONG (limit) & 0x0000ffff), \
    (base), (((fields)>>32) & 0xff00), (fields)>>48
