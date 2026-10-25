#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int main() {
  pid_t p = fork();
  if (p < 0) {
    perror("Forking failed\n");
    exit(1);
  } else if (p == 0) {
    sleep(3);
    // this is just an example. I think you shouldn't do it that way
    char *args[] = {"/bin/ls", "-l", "/usr", NULL};
    execvp(args[0], args);
  } else {
    int status;
    printf("Starting wait for child ls process\n");
    waitpid(p, &status, 0);
    printf("Child ls process should have ended by now\n");
    printf("status: %d\n", status);
  }

  return 0;
}
