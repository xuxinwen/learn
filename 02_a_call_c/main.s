
    .section .text
    .globl _start

_start:
    mov $5, %edi  # 第一个参数
    mov $6, %esi  # 第二个参数

    call add
    mov %eax, %ebx # ebx 程序的状态码
    mov $1, %rax  # 系统调用号

    int $0x80  # 系统调用的中断
