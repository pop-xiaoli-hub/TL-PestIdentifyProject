// V6: 父进程立即退出，子进程sleep后观察 - 经典孤儿进程
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
            printf("I am child. My parent is: %d\n", getppid());
            sleep(2);
            printf("After sleep, my parent is now: %d\n", getppid());
            printf("Child exiting.\n");
            exit(0);
        default:
            printf("I am father (pid=%d). Exiting immediately!\n", getpid());
    }
    printf("After fork, parent exiting... pid:%d\n", getpid());
    exit(0);
}
