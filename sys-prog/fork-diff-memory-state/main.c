#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>

int main() {
  int n = 8;
  int *arr = (int *)malloc(sizeof(int) * n);
  for (int i = 0; i < n; i++) {
    arr[i] = i + 1;
  }

  pid_t p = fork();
  if (p < 0) {
    perror("Forking failed\n");
    exit(1);
  } else if (p == 0) {
    printf("This message is from child process with pid = %d\n", getpid());
    arr[0] = 10;
    sleep(3);
  } else {
    printf("This message is from parent process with pid = %d. It's child "
           "process pid = %d\n",
           getpid(), p);
    arr[1] = 10;
  }

  printf("arr[0] = %d, arr[1] = %d\n", arr[0], arr[1]);

  return 0;
}
