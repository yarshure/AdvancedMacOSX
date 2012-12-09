/* calculate the wall-clock time it takes to read()
   Run with
   sudo dtrace -qs ./readtime.d
*/

syscall::read:entry
{
  ts[pid, probefunc] = timestamp;
}

syscall::read:return
/ts[pid, probefunc] != 0/
{
  delta = timestamp - ts[pid, probefunc];
  printf("read in %s took %d nsecs", execname, delta);
}
