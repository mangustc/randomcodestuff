#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

int main() {
  int pipefd[2];
  if (pipe(pipefd) == -1) {
    perror("Forking failed\n");
    exit(1);
  }

  pid_t p = fork();

  if (p < 0) {
    perror("Forking failed\n");
    exit(1);
  } else if (p == 0) {
    close(pipefd[0]);

    sleep(1);
    char *msg = "This message is from child process";
    write(pipefd[1], msg, strlen(msg) + 1);

    close(pipefd[1]);
  } else {
    close(pipefd[1]);

    char buffer[128];
    ssize_t bytes_read = read(pipefd[0], buffer, 128);
    if (bytes_read > 0) {
      printf("Parent received message from child with: %s\n", buffer);
    }

    close(pipefd[0]);
    wait(NULL);
  }

  return 0;
}
