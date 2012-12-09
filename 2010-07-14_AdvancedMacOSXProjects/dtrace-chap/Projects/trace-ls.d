/* trace the flow of function calls in the open() system call in 
   the kernel for 'ls'
   Run with:
   sudo dtrace -s ./trace-ls.d
*/

#pragma D option flowindent

BEGIN
{
  printf("waiting for 'ls'");
}

syscall::open:entry
/execname == "ls" && guard++ == 0/
{
  self->traceme = 1;
}

fbt:::
/self->traceme/
{
}

syscall:::return
/self->traceme/
{
  self->traceme = 0;
  exit(0);
}
