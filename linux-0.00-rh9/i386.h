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
#define BIT_PRESENT 0x800000000000

#define BIT_APP_CODE_AND_DATA_SEG 0b1 << 44
#define BIT_SPECIAL_SYSTEM_SEG 0b0 << 44

#define BIT_ACCESSED 0x10000000000

#define BIT_BIG 0x40000000000000
#define BIT_DEFAULT 0x40000000000000
#define BIT_AVAILABLE 0x10000000000000
#define BIT_EXPAND_DOWN 0x40000000000
#define BIT_WRITABLE 0x20000000000
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


// 通用 8 位
#define DESC_G_8 0x80
#define DESC_G_64 (DESC_G_8<<48)

#define DESC_AVL_8 0x10
#define DESC_P_8 0x80
#define DESC_P_16 (DESC_P_8<<8)
#define DESC_P_64 (DESC_P_8<<40)
#define DESC_APP_8 0x10
#define DESC_SYS_8 0x00

#define DESC_DATA_8 (DESC_APP_8)
#define DESC_CODE_8 (DESC_APP_8|0x8)

#define DESC_AVL_64 (DESC_AVL_8<<48)
#define DESC_P_64 (DESC_P_8<<40)
#define DESC_APP_64 (DESC_APP_8<<40)
#define DESC_SYS_64 (DESC_SYS_8<<40)

#define DESC_DATA_64 (DESC_DATA_8<<40)
#define DESC_CODE_64 (DESC_CODE_8<<40)

// 数据段描述符 8位
#define DESC_DATA_B_8 0x40
#define DESC_DATA_E_8 0x04
#define DESC_DATA_W_8 0x02

#define DESC_DATA_B_64 (DESC_DATA_B_8<<48)
#define DESC_DATA_E_64 (DESC_DATA_E_8<<40)
#define DESC_DATA_W_64 (DESC_DATA_W_8<<40)

// 代码段描述符 8位
#define DESC_CODE_D_8 0x40
#define DESC_CODE_C_8 0x04
#define DESC_CODE_R_8 0x02

#define DESC_CODE_D_64 (DESC_CODE_D_8<<48)
#define DESC_CODE_C_64 (DESC_CODE_C_8<<40)
#define DESC_CODE_R_64 (DESC_CODE_R_8<<40)

// 系统段描述符
#define DESC_SYS_386_TSS_8 0x09
#define DESC_SYS_386_TSS_16 (DESC_SYS_386_TSS_8<<8)

#define DESC_SYS_LDT_8 0x02
#define DESC_SYS_LDT_16 (DESC_SYS_LDT_8<<8)

#define DESC_DPL3_16 (PL3<<14)

#define desc_64(base, limit, dpl, fields) (\
    ((LONG_LONG(base) & 0xff000000) << 32) | \
    ((LONG_LONG(base) & 0x00ff0000) << 16) | \
    ((LONG_LONG(base) & 0x0000ffff) << 16) | \
    (LONG_LONG(limit) & 0x0000ffff) | \
    (LONG_LONG(limit) & 0xf0000) << 32 | \
    LONG_LONG(fields) \
)

#define desc_data_64(base, limit, dpl, fields) desc_64(base, limit, dpl, fields|DESC_DATA_64|DESC_P_64)
#define desc_code_64(base, limit, dpl, fields) desc_64(base, limit, dpl, fields|DESC_CODE_64|DESC_P_64)

#define def_desc_64kbase(base, limit, dpl, fields) \
    .word (LONG_LONG (limit) & 0x0000ffff), \
    (base), (((fields)>>32) & 0xff00), (fields)>>48
