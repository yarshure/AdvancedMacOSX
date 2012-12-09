/* aggregate read times and show a histogram on exit.
   Run with:
   sudo dtrace -qs avgquant.d
*/

syscall::read:entry
{
    self->ts = timestamp;
}

syscall::read:return
/self->ts/
{
    delta = timestamp - self->ts;
    @quanttime[execname] = quantize(delta);
}
