# 0 "head.S"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 0 "<command-line>" 2
# 1 "head.S"
# head.s contains the 32-bit startup code.
# Two L3 task multitasking. The code of tasks are in kernel area,
# just like the Linux. The kernel code is located at 0x10000.

# 1 "i386.h" 1
# 6 "head.S" 2
# 1 "bios.h" 1
# 7 "head.S" 2

CODE_SEL = ((1) << 3 | (0b000) | (0b00))
DATA_SEL = ((2) << 3 | (0b000) | (0b00))
SCRN_SEL = ((3) << 3 | (0b000) | (0b00))
TSS0_SEL = ((4) << 3 | (0b000) | (0b00))
LDT0_SEL = ((5) << 3 | (0b000) | (0b00))
TSS1_SEL = ((6) << 3 | (0b000) | (0b00))
LDT1_SEL = ((7) << 3 | (0b000) | (0b00))

.global startup_32
.text
startup_32:
 movl DATA_SEL,%eax
 mov %ax,%ds
 lss init_stack,%esp

# setup base fields of descriptors.
 call setup_idt
 call setup_gdt
 movl DATA_SEL,%eax # reload all the segment registers
 mov %ax,%ds # after changing gdt.
 mov %ax,%es
 mov %ax,%fs
 mov %ax,%gs
 lss init_stack,%esp

# setup up timer 8253 chip.
 movb $(0x00|0x30|0x6|0), %al
 movl $0x43, %edx
 outb %al, %dx
 movl $11930, %eax # timer frequency 100 HZ
 movl $0x40, %edx
 outb %al, %dx
 movb %ah, %al
 outb %al, %dx

# setup timer & system call interrupt descriptors.
 movl $(CODE_SEL<<16), %eax
 movw $timer_interrupt, %ax
 movw $((0x0e<<8)|(0x80<<8)), %dx
 movl $0x08, %ecx # The PC default timer int.
 lea idt(,%ecx,8), %esi
 movl %eax,(%esi)
 movl %edx,4(%esi)

 movw $system_interrupt, %ax
 movw $((0x80<<8)|(0x0f<<8)|(0b11<<14)), %dx
 movl $0x80, %ecx
 lea idt(,%ecx,8), %esi
 movl %eax,(%esi)
 movl %edx,4(%esi)

# Move to user mode (task 0)
 pushfl
 andl $0xffffbfff, (%esp)
 popfl
 movl $TSS0_SEL, %eax
 ltr %ax
 movl $LDT0_SEL, %eax
 lldt %ax
 movl $0, current
 sti
 pushl $((2) << 3 | (0b100) | (0b11))
 pushl $init_stack
 pushfl
 pushl $((1) << 3 | (0b100) | (0b11))
 pushl $task0
 iret


setup_gdt:
 lgdt lgdt_opcode
 ret

setup_idt:
 lea ignore_int,%edx
 movl $(((2) << 3 | (0b000) | (0b00)) << 16), %eax
 movw %dx,%ax
 movw $((0x0e<<8)|(0x80<<8)),%dx
 lea idt,%edi
 mov $256,%ecx
rp_sidt:
 movl %eax,(%edi)
 movl %edx,4(%edi)
 addl $8,%edi
 dec %ecx
 jne rp_sidt
 lidt lidt_opcode
 ret

# -----------------------------------
write_char:
 push %gs
 pushl %ebx
 mov $SCRN_SEL, %ebx
 mov %bx, %gs
 movl scr_loc, %ebx
 shl $1, %ebx
 movb %al, %gs:(%ebx)
 shr $1, %ebx
 incl %ebx
 cmpl $2000, %ebx
 jb 1f
 movl $0, %ebx
1: movl %ebx, scr_loc
 popl %ebx
 pop %gs
 ret



.align 2
ignore_int:
 push %ds
 pushl %eax
 movl $0x10, %eax
 mov %ax, %ds
 movl $67, %eax
 call write_char
 popl %eax
 pop %ds
 iret


.align 2
timer_interrupt:
 push %ds
 pushl %eax
 movl $0x10, %eax
 mov %ax, %ds
 movb $0x20, %al
 outb %al, $0x20
 movl $1, %eax
 cmpl %eax, current
 je 1f
 movl %eax, current
 ljmp $TSS1_SEL, $0
 jmp 2f
1: movl $0, current
 ljmp $TSS0_SEL, $0
2: popl %eax
 pop %ds
 iret


.align 2
system_interrupt:
 push %ds
 pushl %edx
 pushl %ecx
 pushl %ebx
 pushl %eax
 movl $0x10, %edx
 mov %dx, %ds
 call write_char
 popl %eax
 popl %ebx
 popl %ecx
 popl %edx
 pop %ds
 iret


current:.long 0
scr_loc:.long 0

.align 2
lidt_opcode:
 .word 256*8-1 # idt contains 256 entries
 .long idt # This will be rewrite by code.
lgdt_opcode:
 .word (end_gdt-gdt)-1 # so does gdt
 .long gdt # This will be rewrite by code.

 .align 8
idt: .fill 256,8,0 # idt is uninitialized

gdt: .quad 0x0000000000000000
 .quad ( (((0) & 0xff000000) << 32) | (((0) & 0x00ff0000) << 16) | (((0) & 0x0000ffff) << 16) | ((0x7ff) & 0x0000ffff) | ((0x7ff) & 0xf0000) << 32 | (((0x02<<40)|(0x80<<48)|(0x40<<48))|((0x10|0x8)<<40)|(0x80<<40)) )



 .quad ( (((0) & 0xff000000) << 32) | (((0) & 0x00ff0000) << 16) | (((0) & 0x0000ffff) << 16) | ((0x7ff) & 0x0000ffff) | ((0x7ff) & 0xf0000) << 32 | (((0x02<<40)|(0x80<<48)|(0x40<<48))|((0x10)<<40)|(0x80<<40)) )



 .quad ( (((0xb8000) & 0xff000000) << 32) | (((0xb8000) & 0x00ff0000) << 16) | (((0xb8000) & 0x0000ffff) << 16) | ((0x2) & 0x0000ffff) | ((0x2) & 0xf0000) << 32 | (((0x02<<40) | (0x80<<48) | (0x40<<48))|((0x10)<<40)|(0x80<<40)) )




 .word 0x68, tss0, (0x09<<8)|(0b11<<14)|(0x80<<8), 0



 .word 0x40, ldt0, (0x02<<8)|(0b11<<14)|(0x80<<8), 0



 .word 0x68, tss1, (0x09<<8)|(0b11<<14)|(0x80<<8), 0



 .word 0x40, ldt1, (0x02<<8)|(0b11<<14)|(0x80<<8), 0




end_gdt:
 .fill 128,4,0
init_stack: # Will be used as user stack for task0.
 .long init_stack
 .word ((2) << 3 | (0b000) | (0b00))


.align 8
ldt0: .quad 0x0000000000000000
 .quad ( (((0) & 0xff000000) << 32) | (((0) & 0x00ff0000) << 16) | (((0) & 0x0000ffff) << 16) | ((0x3ff) & 0x0000ffff) | ((0x3ff) & 0xf0000) << 32 | (((0x02<<40)|(0x80<<48)|(0x40<<48))|((0x10|0x8)<<40)|(0x80<<40)) )


 .quad ( (((0) & 0xff000000) << 32) | (((0) & 0x00ff0000) << 16) | (((0) & 0x0000ffff) << 16) | ((0x3ff) & 0x0000ffff) | ((0x3ff) & 0xf0000) << 32 | (((0x02<<40)|(0x80<<48)|(0x40<<48))|((0x10)<<40)|(0x80<<40)) )



tss0: .long 0
 .long krn_stk0, ((2) << 3 | (0b000) | (0b00))
 .long 0, 0, 0, 0, 0
 .long 0, 0, 0, 0, 0
 .long 0, 0, 0, 0, 0
 .long 0, 0, 0, 0, 0, 0
 .long LDT0_SEL, 0x8000000

 .fill 128,4,0
krn_stk0:


.align 8
ldt1: .quad 0x0000000000000000
 .quad ( (((0) & 0xff000000) << 32) | (((0) & 0x00ff0000) << 16) | (((0) & 0x0000ffff) << 16) | ((0x3ff) & 0x0000ffff) | ((0x3ff) & 0xf0000) << 32 | (((0x02<<40)|(0x80<<48)|(0x40<<48))|((0x10|0x8)<<40)|(0x80<<40)) )


 .quad ( (((0) & 0xff000000) << 32) | (((0) & 0x00ff0000) << 16) | (((0) & 0x0000ffff) << 16) | ((0x3ff) & 0x0000ffff) | ((0x3ff) & 0xf0000) << 32 | (((0x02<<40)|(0x80<<48)|(0x40<<48))|((0x10)<<40)|(0x80<<40)) )



tss1: .long 0
 .long krn_stk1, ((2) << 3 | (0b000) | (0b00))
 .long 0, 0, 0, 0, 0
 .long task1, 0x200
 .long 0, 0, 0, 0
 .long usr_stk1, 0, 0, 0
 .long ((2) << 3 | (0b100) | (0b11)),((1) << 3 | (0b100) | (0b11)), ((2) << 3 | (0b100) | (0b11)),((2) << 3 | (0b100) | (0b11)), ((2) << 3 | (0b100) | (0b11)),((2) << 3 | (0b100) | (0b11))



 .long LDT1_SEL, 0x8000000

 .fill 128,4,0
krn_stk1:


task0:
 movl $0x17, %eax
 movw %ax, %ds
 movb $65, %al
 int $0x80
 movl $0xfff, %ecx
1: loop 1b
 jmp task0

task1:
 movl $0x17, %eax
 movw %ax, %ds
 movb $66, %al
 int $0x80
 movl $0xfff, %ecx
1: loop 1b
 jmp task1

 .fill 128,4,0
usr_stk1:
