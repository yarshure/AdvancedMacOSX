/* Calculate number of read calls and the average calltime.
   output is suboptimal.
   Run with:
   sudo dtrace -qs avgread-1.d
*/

syscall::read:entry
{
    @calls[execname] = count();
    self->ts = timestamp;
}

syscall::read:return
/self->ts/
{
    delta = timestamp - self->ts;
    @averagetime[execname] = avg(delta);
}
