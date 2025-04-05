#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  int n, i;
  int statuses[64]; // NPROC is typically defined as 64
  int child_count = 5; // Create 5 child processes
  
  printf("Parent: creating %d children\n", child_count);
  
  // Create multiple child processes
  for(i = 0; i < child_count; i++) {
    int pid = fork();
    if(pid < 0) {
      printf("fork failed\n");
      exit(1);
    }
    if(pid == 0) {
      // Child process
      printf("Child %d: starting, will exit with status %d\n", getpid(), i+1);
      sleep(10 * (i+1)); // Sleep for different amounts of time
      printf("Child %d: exiting with status %d\n", getpid(), i+1);
      exit(i+1); // Exit with different status codes
    }
  }
  
  // Parent process waits for all children
  printf("Parent: waiting for all children to finish\n");
  int ret = waitall(&n, statuses);
  
  if(ret == 0) {
    printf("Parent: all %d children finished\n", n);
    printf("Exit statuses:\n");
    for(i = 0; i < n; i++) {
      printf("  Child %d: status %d\n", i, statuses[i]);
    }
  } else {
    printf("Parent: waitall failed with return value %d\n", ret);
  }
  
  exit(0);
}