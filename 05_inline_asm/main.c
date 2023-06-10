#include <stdio.h>


/*
asm asm-qualifiers ( AssemblerTemplate 
                      : OutputOperands
                      : InputOperands
                      : Clobbers
                      : GotoLabels)

[ [asmSymbolicName] ] constraint (cvariablename)

constraint:
    m
    r
    i

Constraint Modifier Characters
    =
    +
*/


int main() {
    int a = 0;
    int b = 1;

    asm(
        "movl %1, %0"
        : "=m" (a)
        : "r" (b)
    );

    printf("%d\n", a);

    return 0;
}
