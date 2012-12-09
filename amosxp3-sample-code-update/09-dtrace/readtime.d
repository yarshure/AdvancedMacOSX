/* calculate the wall-clock time it takes to read()
   Run with
   sudo dtrace -qs ./readtime.d
*/

syscall::read:entry
/execname != "Terminal" && execname != "Activity Monito" && execname != "activitymonitor"/
{
    self->ts[pid, probefunc] = timestamp;
}

syscall::read:return
/self->ts[pid, probefunc] != 0/
{
    delta = timestamp - self->ts[pid, probefunc];
    printf ("read in %s took %d nsecs\n", execname, delta);
}
