#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

#define totalQs 4
#define priority_boost 48
// extern totalQs;
// 
struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;



unsigned long randstate = 1;

unsigned int random_gene()
{
  randstate = randstate * 1664525 + 1013904223;
  return (randstate % 0x7FFFFFFF);
}

#ifdef MLFQ


mlfq_que mlfq[totalQs];



void initialize(){
  mlfq[0].time_slice = 1;
  mlfq[1].time_slice = 4;
  mlfq[2].time_slice = 8;
  mlfq[3].time_slice = 16;

  for(int i=0;i<totalQs;i++){
    mlfq[i].head_ptr = 0;
    mlfq[i].tail_ptr = 0;
    for(int j=0;j<NPROC;j++){
      mlfq[i].process[j] = 0;
    }
  }
  
}


/// push operation  // can add % operation
void enque_mlfq(struct proc* p,int que_no){
  // printf("-----hello\n");
  if(mlfq[que_no].tail_ptr < NPROC){
    int n = mlfq[que_no].tail_ptr;
    mlfq[que_no].process[n] = p;
    mlfq[que_no].tail_ptr++;

    p->is_PQue = 1;
    p->CQue_no = que_no;
  }
}

void add_front_mlfq(struct proc* p,int que_no){
  // mlfq[que_no].tail_ptr ++;
  if(mlfq[que_no].tail_ptr  < NPROC){

  for(int i = mlfq[que_no].tail_ptr ; i > 0 ; i-- ){
    mlfq[que_no].process[i] = mlfq[que_no].process[i-1];    
  }
   mlfq[que_no].tail_ptr ++;
   mlfq[que_no].process[0] = p;  
  p->CQue_no = que_no;
  p->is_PQue = 1;
  
  }else{
    printf("que is full \n");
  }

}

struct proc* deque_mlfq(int que_no){
  if(mlfq[que_no].tail_ptr > 0){
     struct proc* p = mlfq[que_no].process[0];

     mlfq[que_no].process[0] = 0;
    for(int i=0;i<NPROC-1;i++){
      mlfq[que_no].process[i] = mlfq[que_no].process[i+1];
    }
    mlfq[que_no].process[mlfq[que_no].tail_ptr] = 0;
    mlfq[que_no].tail_ptr --;
    p->is_PQue = 0;
    return p; 
  }
  else{
  printf("Que is empty\n");
  }

  return 0;

}

// remove process

void remProcess(int que_no,struct proc*p){
  for(int i= mlfq[que_no].head_ptr ; i< mlfq[que_no].tail_ptr;i++ ){
    if(mlfq[que_no].process[i]  == p){

      for(int j=i;j<mlfq[que_no].tail_ptr - 1;j++){
        mlfq[que_no].process[i] = mlfq[que_no].process[j+1];
      }

      mlfq[que_no].tail_ptr -- ;
      // p->is_PQue = 0;
      break;
    }
  }

  p->is_PQue = 0;
}

#endif

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
  randstate = ticks;
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  p->rtime = 0;
  p->etime = 0;
  p->ctime = ticks;
#ifdef MLFQ
  p->CQue_no = 0;
  p->is_PQue = 0;
  p->WaitTime = 0;
  p->RunTime = 0;

#endif
  // p->RunTime = 0;
  
#ifdef LBS
  p->tickets = 1;
  p->arrival_time = ticks;
#endif
  // #ifdef MLFQ
  // printf("Allocating process: tickets=%d, ctime=%d\n", p->tickets, p->ctime);
  //   enque_mlfq(p, p->CQue_no); 
  // #endif
  // release(&p->lock);
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
  #ifdef MLFQ
  p->is_PQue = 0;
  #endif
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;
  
  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;
  
  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }
  
  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;
  // printf("innnnnvfeken\n");
  // #ifdef MLFQ
  // initialize();
  // #endif

  p = allocproc();
  // printf("in userinit");
  initproc = p;
  #ifdef MLFQ
  initialize();
  #endif

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer
  
  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  // printf("state111...:%s\n",state);

  release(&p->lock);
  
  // printf("state...:%s\n",p->state);
  // printf("hjvkvbksbc\n");

 
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }
  // printf("np_pid: %d\n",np->pid);


  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  //
  np->tickets = p->tickets;
  //  printf("np_tickets: %d\n",np->tickets);
  



  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();


  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          for (int i = 0; i < NSYSCALLS; i++) {
            p->syscallCount[i] = pp->syscallCount[i];
          }
          
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}




// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();


  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
  #ifdef LBS
   

    int total_tic = 0;
    struct proc* sele_proc = 0;

    // Iterate over the process table to count total tickets.
    for (p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if (p->state == RUNNABLE) {
            total_tic += p->tickets;
        }
        release(&p->lock);
    }

    if (total_tic == 0) {
      // printf("tc :%d\n",total_tic);
        continue;  // No runnable processes
    }
  
    int winner = random_gene() % total_tic + 1;
    int tic_sum = 0;
    // printf("winner: %d\n",winner);
    // printf("Winner ticket number: %d\n", winner);



    // Select the winning process.
    for (p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if (p->state == RUNNABLE) {
          // printf("ticsum :%d\n",tic_sum);
            tic_sum += p->tickets;
            if (tic_sum >= winner) {
                sele_proc = p;  // Temporarily select the process as the winner
                // printf("p->tickets :%d == pid : %d\n",p->tickets,p->pid);
               release(&p->lock);
                break;          // Exit the loop once a potential winner is found
            }
        }
        release(&p->lock);
    }

    if (sele_proc != 0) {
        // Now we need to check for fairness: whether there are earlier processes with the same ticket count
        struct proc* fair_proc = sele_proc;

        for (p = proc; p < &proc[NPROC]; p++) {
            acquire(&p->lock);
            // Check for other RUNNABLE processes with the same ticket count
            if (p->state == RUNNABLE && p->tickets == fair_proc->tickets) {
                if (p->arrival_time < fair_proc->arrival_time) {
                    fair_proc = p;  // Select the earlier process if it exists
                }
            }
            release(&p->lock);
        }

        // Lock the selected fair process for execution
        acquire(&fair_proc->lock);
        
        // Ensure the process is not already running
        if (fair_proc->state != RUNNING) {
            fair_proc->state = RUNNING;  // Set the state to RUNNING
            c->proc = fair_proc;          // Update current process context
            swtch(&c->context, &fair_proc->context);
            //  printf("Selected process PID: %d with tickets: %d\n", fair_proc->pid, fair_proc->tickets);
            c->proc = 0;
            release(&fair_proc->lock);
            // printf("Selected process PID: %d with tickets: %d\n", fair_proc->pid, fair_proc->tickets);


            // printf("Returned from context switch\n");
        } else {
            
            release(&fair_proc->lock);
        }

        sele_proc = 0; // Reset the selected process for the next iteration
    }
  // #endif

  #elif defined(MLFQ)
  

    
    for(p = proc;p < &proc[NPROC] ;p++){
      // release(&p->lock);
      // printf("state:%s\n",p->state);
      acquire(&p->lock);
      //  printf("queue: %d-- %s-- %d-- %s\n", p->pid, p->name, p->CQue_no, p->state);
      if (p->state == SLEEPING || p->state == UNUSED)
      {
        // printf("444\n");
        release(&p->lock);
        continue;
      }
      if(p->state == RUNNABLE && p->is_PQue == 0){

        enque_mlfq(p,p->CQue_no);
        p->is_PQue = 1;
      }
      if((p->state == UNUSED || p->state == ZOMBIE ) && p->is_PQue == 1){
        remProcess(p->CQue_no,p);
        p->is_PQue = 0;
      }
      release(&p->lock);
    }

      struct proc* work_proc = 0;

      // Round-robin logic for the lowest priority queue
      for (int i = 0; i < totalQs; i++) {
        if (work_proc != 0) {
          break;
        }

        // Dequeue from the lowest priority queue (round-robin)
        if (i == totalQs - 1) {
          // For the lowest priority queue, continue dequeuing until you find a RUNNABLE process
          while (mlfq[i].tail_ptr > 0) {
            work_proc = deque_mlfq(i);
            work_proc->is_PQue = 0;

            if (work_proc->state == RUNNABLE) {
              acquire(&work_proc->lock);
              work_proc->state = RUNNING;
              c->proc = work_proc;
              swtch(&c->context, &work_proc->context);
              c->proc = 0;
              release(&work_proc->lock);

              // Re-enqueue at the end of the lowest priority queue if still RUNNABLE
              acquire(&work_proc->lock);
              if (work_proc->state == RUNNABLE || work_proc->state == RUNNING) {
                enque_mlfq(work_proc, totalQs - 1);  // Re-enqueue in the lowest queue
              }
              release(&work_proc->lock);

              break;
            }
          }
        }
        // For other priority queues (normal MLFQ behavior)
        else {
          while (mlfq[i].tail_ptr > 0) {
            work_proc = deque_mlfq(i);
            work_proc->is_PQue = 0;

            if (work_proc->state == RUNNABLE) {
              add_front_mlfq(work_proc,work_proc->CQue_no);
             
              acquire(&work_proc->lock);
              work_proc->state = RUNNING;
              c->proc = work_proc;
              swtch(&c->context, &work_proc->context);
              c->proc = 0;
      //         printf("pid: %d, queue: %d, rtime: %d, wtime: %d\n",
      //  work_proc->pid, work_proc->CQue_no, work_proc->RunTime, work_proc->WaitTime);

              release(&work_proc->lock);

              break;
            }
          }
        }
      }

  #else
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;

      }
      release(&p->lock);
    }
  #endif
  }
}
  

// 
// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
      // Set the process state to RUNNABLE if not SLEEPING
#ifdef MLFQ
    if (p->state != SLEEPING) {
        p->state = RUNNABLE;  // Only set to RUNNABLE if not sleeping
    }
#else
    // For non-MLFQ, just set it to RUNNABLE
    p->state = RUNNABLE;
#endif

  // p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;
  #ifdef MLFQ
  if(p->is_PQue==1){
  remProcess(p->CQue_no,p);
  }
  #endif

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
      }
      release(&p->lock);
      #ifdef MLFQ
      if(p-> is_PQue== 0){
      enque_mlfq(p,p->CQue_no);
      }
      #endif
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    // printf("PID %d, State %d, Queue %d\n", p->pid, p->state, p->CQue_no);
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
   
    printf("%d %s %s", p->pid, state, p->name);


// #ifdef MLFQ
//     // Print MLFQ-specific information (Current Queue and RunTime)
//     printf(" pid : %d -Queue: %d-RunTime: %d - WaitTime: %d - State : %s\n",p->pid, p->CQue_no, p->RunTime, p->WaitTime,state);
// #endif

// #ifdef LBS
//     // Print LBS-specific information (Number of Tickets)
//     printf(" Tickets: %d\n", p->tickets);
//     printf("pid: %d , state :%s,rtime : %d , waittime:%d\n",p->pid,state,p->rtime,p->ctime);
// #endif
    printf("\n");
  }
}

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->ctime - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;

      p->RunTime++;

      // printf("Runtime :%d\n",p->RunTime);
    }
    else if(p->state == RUNNABLE){
      p->WaitTime ++;
    }
    
    release(&p->lock);
  }
#ifdef DOGRAPH
  for (struct proc *prs = proc; prs < &proc[NPROC]; prs++)
  {
    if (prs->state == RUNNING || prs->state == RUNNABLE )
    {
      printf("GRAPH %d %d %d %d\n", prs->pid, ticks, prs->CQue_no, prs->state);
    }
  }
#endif
  
}


