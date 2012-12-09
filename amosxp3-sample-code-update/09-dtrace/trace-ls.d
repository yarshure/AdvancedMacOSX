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
    self->traceIt = 1;
}

fbt:::
/self->traceIt/
{
}

syscall:::return
/self->traceIt/
{
    self->traceIt = 0;
    exit (0);
}
