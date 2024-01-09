#  head.s contains the 32-bit startup code.
#  Two L3 task multitasking. The code of tasks are in kernel area, 
#  just like the Linux. The kernel code is located at 0x10000. 

#include "i386.h"
#include "8253.h"

CODE_SEL	= _selector(1, GDT_TI, PL0)
DATA_SEL	= _selector(2, GDT_TI, PL0)
SCRN_SEL	= _selector(3, GDT_TI, PL0)
TSS0_SEL	= _selector(4, GDT_TI, PL0)
LDT0_SEL	= _selector(5, GDT_TI, PL0)
TSS1_SEL	= _selector(6, GDT_TI, PL0)
LDT1_SEL	= _selector(7, GDT_TI, PL0)

.global startup_32
.text
startup_32:
	movl DATA_SEL,%eax
	mov %ax,%ds
	lss init_stack,%esp

# setup base fields of descriptors.
	call setup_idt
	call setup_gdt
	movl DATA_SEL,%eax		# reload all the segment registers
	mov %ax,%ds		# after changing gdt. 
	mov %ax,%es
	mov %ax,%fs
	mov %ax,%gs
	lss init_stack,%esp

# setup up timer 8253 chip.
	movb $(C8253_CHANNEL_0|C8253_RW|C8253_METHOD_3|C8253_BIN_COUNTER), %al
	movl $C8253_CTL_PORT, %edx
	outb %al, %dx
	movl $C8253_FREQUENCY_100HZ, %eax        # timer frequency 100 HZ 
	movl $C8253_CHANNEL_0_PORT, %edx
	outb %al, %dx
	movb %ah, %al
	outb %al, %dx

# setup timer & system call interrupt descriptors.
	movl $(CODE_SEL<<16), %eax	
	movw $timer_interrupt, %ax
	movw $0x8E00, %dx
	movl $0x08, %ecx              # The PC default timer int.
	lea idt(,%ecx,8), %esi
	movl %eax,(%esi) 
	movl %edx,4(%esi)
	movw $system_interrupt, %ax
	movw $0xef00, %dx
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
	pushl $_selector(2, LDT_TI, PL3)
	pushl $init_stack
	pushfl
	pushl $_selector(1, LDT_TI, PL3)
	pushl $task0
	iret

/****************************************/
setup_gdt:
	lgdt lgdt_opcode
	ret

setup_idt:
	lea ignore_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax		/* selector = 0x0008 = cs */
	movw $0x8E00,%dx	/* interrupt gate - dpl=0, present */
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
#	pushl %eax
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
1:	movl %ebx, scr_loc	
#	popl %eax
	popl %ebx
	pop %gs
	ret

/***********************************************/
/* This is the default interrupt "handler" :-) */
.align 2
ignore_int:
	push %ds
	pushl %eax
	movl $0x10, %eax
	mov %ax, %ds
	movl $67, %eax            /* print 'C' */
	call write_char
	popl %eax
	pop %ds
	iret

/* Timer interrupt handler */ 
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
1:	movl $0, current
	ljmp $TSS0_SEL, $0
2:	popl %eax
	pop %ds
	iret

/* system call handler */
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

/*********************************************/
current:.long 0
scr_loc:.long 0

.align 2
lidt_opcode:
	.word 256*8-1		# idt contains 256 entries
	.long idt		# This will be rewrite by code. 
lgdt_opcode:
	.word (end_gdt-gdt)-1	# so does gdt 
	.long gdt		# This will be rewrite by code.

	.align 8
idt:	.fill 256,8,0		# idt is uninitialized

gdt:	.quad 0x0000000000000000	/* NULL descriptor */
	.quad _descriptor( 
        0, 0x7ff, PL0,  
        (BIT_TYPE_EXE | BIT_READABLE | BIT_GRANULARITY | BIT_BIG | BIT_PRESENT) 
    ) /* 8Mb 0x08, base = 0x00000 */
	.quad _descriptor( 
        0, 0x7ff, PL0,  
        (BIT_TYPE_DATA | BIT_WRITABLE | BIT_GRANULARITY | BIT_BIG | BIT_PRESENT) 
    ) /* 8Mb 0x10 */
	.quad _descriptor(
        0xb8000, 0x2, PL0, 
        (BIT_TYPE_DATA | BIT_WRITABLE | BIT_GRANULARITY | BIT_BIG | BIT_PRESENT)
    ) /* screen 0x18 - for display */

	def_descriptor_64kbase(
		tss0, 0x68, PL3, (BIT_386TSS|BIT_PRESENT)
	) # .word 0x0068, tss0, 0xe900, 0x0	

	def_descriptor_64kbase(
		ldt0, 0x40, PL3, (BIT_PRESENT|BIT_TYPE_LDT)
	) # .word 0x0040, ldt0, 0xe200, 0x0	# LDT0 descr 0x28
	
	def_descriptor_64kbase(
		tss1, 0x68, PL3, (BIT_PRESENT|BIT_386TSS)
	) # .word 0x0068, tss1, 0xe900, 0x0	# TSS1 descr 0x30
	
	def_descriptor_64kbase(
		ldt1, 0x40, PL3, (BIT_PRESENT|BIT_TYPE_LDT)
	) # .word 0x0040, ldt1, 0xe200, 0x0	# LDT1 descr 0x38
	
end_gdt:
	.fill 128,4,0
init_stack:                          # Will be used as user stack for task0.
	.long init_stack
	.word _selector(2, GDT_TI, PL0)

/*************************************/
.align 8
ldt0:	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff	# 0x0f, base = 0x00000
	.quad 0x00c0f200000003ff	# 0x17

tss0:	.long 0 			/* back link */
	.long krn_stk0, 0x10		/* esp0, ss0 */
	.long 0, 0, 0, 0, 0		/* esp1, ss1, esp2, ss2, cr3 */
	.long 0, 0, 0, 0, 0		/* eip, eflags, eax, ecx, edx */
	.long 0, 0, 0, 0, 0		/* ebx esp, ebp, esi, edi */
	.long 0, 0, 0, 0, 0, 0 		/* es, cs, ss, ds, fs, gs */
	.long LDT0_SEL, 0x8000000	/* ldt, trace bitmap */

	.fill 128,4,0
krn_stk0:
#	.long 0

/************************************/
.align 8
ldt1:	.quad 0x0000000000000000
	.quad 0x00c0fa00000003ff	# 0x0f, base = 0x00000
	.quad 0x00c0f200000003ff	# 0x17

tss1:	.long 0 			/* back link */
	.long krn_stk1, _selector(2, GDT_TI, PL0)		/* esp0, ss0 */
	.long 0, 0, 0, 0, 0		/* esp1, ss1, esp2, ss2, cr3 */
	.long task1, 0x200		/* eip, eflags */
	.long 0, 0, 0, 0		/* eax, ecx, edx, ebx */
	.long usr_stk1, 0, 0, 0		/* esp, ebp, esi, edi */
	.long 0x17,0x0f,0x17,0x17,0x17,0x17 /* es, cs, ss, ds, fs, gs */
	.long LDT1_SEL, 0x8000000	/* ldt, trace bitmap */

	.fill 128,4,0
krn_stk1:

/************************************/
task0:
	movl $0x17, %eax
	movw %ax, %ds
	movb $65, %al              /* print 'A' */
	int $0x80
	movl $0xfff, %ecx
1:	loop 1b
	jmp task0 

task1:
	movl $0x17, %eax
	movw %ax, %ds
	movb $66, %al              /* print 'B' */
	int $0x80
	movl $0xfff, %ecx
1:	loop 1b
	jmp task1

	.fill 128,4,0 
usr_stk1:
