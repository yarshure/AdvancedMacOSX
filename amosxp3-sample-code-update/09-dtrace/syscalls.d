/* show all system calls being made, system-wide
   Run with
   sudo dtrace -qs syscalls.d
*/

syscall::read*:return
/execname != "dtrace" && execname != "Terminal" && execname != "Finder"/
{
    printf ("%s fired in %s\n", probefunc, execname);
}
