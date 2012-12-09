/* show all system calls being made, system-wide
   Run with
   sudo dtrace -qs syscalls.d
*/

syscall:::
/execname != "dtrace"/
{
  printf("%s fired in %s", probefunc, execname);
}
