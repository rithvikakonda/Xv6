

#include "kernel/types.h"
#include "user/user.h"
#include "kernel/syscall.h"

int
main(int argc, char *argv[])
{
    if (argc < 3) {
        fprintf(2, "Usage: syscount <mask> <command> [args...]\n");
        exit(1);
    }
    int mask = atoi(argv[1]);

    int pid = fork();
    if (pid < 0) {
        fprintf(2, "fork failed\n");
        exit(1);
    }

    if (pid == 0) { // Child process
        exec(argv[2], &argv[2]);
        fprintf(2, "exec failed\n");
        exit(1);
    }

   
    wait(0);

    uint64 count = getSysCount(mask);
    int syscall_num = 0;
    while (mask > 1) {
        syscall_num++;
        mask >>= 1;
    }

    char *syscall_names[] = {
        "fork", "exit", "wait", "pipe", "read", "kill", "exec", "fstat", "chdir", "dup",
        "getpid", "sbrk", "sleep", "uptime", "open", "write", "mknod", "unlink", "link", "mkdir",
        "close", "waitx", "getSysCount" ,"sigalarm" ,"sigreturn","settickets" // Add new syscalls here
    };

    if (syscall_num < 32) { // Assume there are 24 syscalls for now
        printf("PID %d called %s %d times.\n", pid, syscall_names[syscall_num-1], count);
    }

    exit(0);
}
