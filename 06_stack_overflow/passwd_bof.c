#include <stdio.h>
#include <string.h>


int main(int argc, char *argv[]) {
    char passwd[128];  // 不初始化了，影响调试
    strcpy(passwd, argv[1]);
    printf("Password changed successfully\n");
    return 0;
}
