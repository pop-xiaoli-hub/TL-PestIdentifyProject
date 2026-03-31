// V4: 孤儿进程 - 父进程先退出，子进程sleep后查看ppid变化
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(void) {
    pid_t pid;
    printf("Before fork ... initialized pid:%d current pid:%d\n", pid, getpid());
    switch (pid = fork()) {
        case -1:
            printf("fork call fail\n");
            fflush(stdout);
            exit(1);
        case 0:
            sleep(1);
            printf("I am child.\n");
            printf("The pid of child is: %d\n", getpid());
            printf("THe pid of child's parent is: %d\n", getppid());
            printf("Child waiting...\n");
            sleep(2);
            printf("The parent pid after parent die: %d\n", getppid());
            exit(0);
        default:
            sleep(1);
            printf("I am father.\n");
            printf("The pid of parent is: %d\n", getpid());
            printf("The pid of parent's child is: %d\n", pid);
            sleep(1);
    }
    printf("After fork, program exiting... current pid:%d, current ppid:%d\n", getpid(), getppid());
    exit(0);
}
