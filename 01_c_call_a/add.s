
    .globl add
    .type add, @function
add:
    push %rbp
    mov %rsp, %rbp

    mov %esi, %eax
    add %edi, %eax

    mov %rbp, %rsp
    pop %rbp
    ret
