#include <stdio.h>
#include <stdlib.h>

typedef struct node 
{
    int val;
    struct node *next;
} node;

node * init() 
{
    /*
    初始化测试链表
    */

    node *head = NULL;
    node **curr = &head;

    for (int i=0; i<10; i++) {
        *curr = (node *)malloc(sizeof(node));

        if (*curr == NULL) {
            printf("malloc error\n");
            exit(-1);
        }
        (*curr)->val = i;
        (*curr)->next = NULL;

        curr = &(*curr)->next;
    }
    return head;
}

void walk(node *head) {
    for (node *curr = head; curr; curr = curr->next) 
    {
        printf("val=%d\n", curr->val);
    }
}

node * remove_if_v1(node * head)  
{  
    for (node * prev = NULL, * curr = head; curr != NULL; )  
    {  
        node * next = curr->next;  
        if (curr->val == 5)
        {  
            if (prev)  
                prev->next = curr->next;  
            else  
                head = curr->next;  
            free(curr);  
        }  
        else  
            prev = curr;  
        curr = next;  
    }  
    return head;  
} 

void remove_if_v2(node ** head)  
{  
    for (node** curr = head; *curr; )  
    {  
        node * entry = *curr;  
        if (entry->val  == 5)  
        {  
            *curr = entry->next;  
            free(entry);  
        }  
        else  
            curr = &entry->next;  
    }  
}  

int main() 
{
    node *head = NULL;
    head = init();
    walk(head);
    // remove_if_v1(head);
    remove_if_v2(&head);
    printf("--------------------------------");
    walk(head);
    return 0;
}