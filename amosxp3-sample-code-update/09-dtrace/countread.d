/* count the number of times the read() system call is made by any proces.
   Run with
   sudo dtrace -s ./countread.d
*/

BEGIN
{
    printf("bork");
}

syscall::*recv*:entry
{
/*     @calls[probefunc] = count(); */
    @calls[execname] = count();
}
