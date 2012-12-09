/* count the number of times the read() system call is made by any proces.
   Run with
   sudo dtrace -s ./countread.d
*/

syscall::read:entry
{
    @calls[execname] = count();
}
