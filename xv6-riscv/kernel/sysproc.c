#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"
// added comment commit check
uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

#define MAX_CHILDREN 16

uint64 
sys_forkn(void) 
{
    int n;
    uint64 pids;  // Userspace pointer for child PIDs
    argint(0, &n);
    argaddr(1, &pids);
    // if (n != 0 || pids != 0) {
    //     return -1; // Invalid arguments
    // }

    if (n < 1 || n > MAX_CHILDREN) {
        return -1; // Restrict range of child processes
    }

    int created = 0;
    int child_pids[MAX_CHILDREN];

    // Fork n child processes
    for (int i = 0; i < n; i++) {
        int pid = fork();
        if (pid < 0) {
            // Cleanup: Kill already created processes
            for (int j = 0; j < created; j++) {
                kill(child_pids[j]);
            }
            return -1;  // Indicate failure
        } else if (pid == 0) {
            return i + 1;  // Child returns its index (1-based)
        }
        child_pids[created++] = pid;
    }

    // Copy child PIDs to userspace
    if (copyout(myproc()->pagetable, pids, (char *)child_pids, sizeof(int) * n) < 0) {
        return -1;
    }

    return 0; // Success, parent returns 0
}


uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_waitall(void) // added
{
  uint64 p; 
  uint64 statuses; 
  
  argaddr(0, &p);
  argaddr(1, &statuses);
  
  return waitall(p ,statuses);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}
