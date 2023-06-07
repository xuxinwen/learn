#include <stdio.h>


int add(int x, int y);
/*
push %rbp
mov %rsp, %rbp

rax
1
mov %rbp, %rsp
pop %rbp
ret
*/


int main() {
    int a = 5;
    int b = 6;
    int c = 0;

    c = add(a, b); // call add

    printf("%d\n", c);
    return 0;
}
