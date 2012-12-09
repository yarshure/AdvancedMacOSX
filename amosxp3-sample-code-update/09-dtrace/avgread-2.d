/* Calculate stats about the read 
   Run with:
   sudo dtrace -qs avgread-2.d
*/

syscall::read:entry
{
    self->ts = timestamp;
}

syscall::read:return
/self->ts/
{
    delta = timestamp - self->ts;
    @averagetime[execname] = avg(delta);
    @callcount[execname] = count();
    @mintime[execname] = min(delta);
    @maxtime[execname] = max(delta);
    self->ts = 0;
}

END
{
    printf ("average time\n");
    printa ("%20s %@d\n", @averagetime);
  
    printf ("\ncall count\n");
    printa ("%20s %@d\n", @callcount);

    printf ("\nmintime\n");
    printa ("%20s %@d\n", @mintime);

    printf ("\nmaxtime\n");
    printa ("%20s %@d\n", @maxtime);
}
