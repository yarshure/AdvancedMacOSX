/* Show the system load average
   Run with
   sudo dtrace -qs loadaverage.d
*/


profile:::tick-5sec
{
     this->fscale = `averunnable.fscale;
     this->loadInteger = `averunnable.ldavg[0] / this->fscale;
     this->loadDecimal = ((`averunnable.ldavg[0] % this->fscale) * 100) 
                         / this->fscale;
     printf ("%d.%d\n", this->loadInteger, this->loadDecimal);
}
