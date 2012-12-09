/* show the profile (timer) provider.
   Run with
   sudo dtrace -s lubdub.d
*/

profile:::tick-5sec
{
    trace ("five second timer");
}

profile:::tick-1min
{
    trace ("one minute timer");
}

profile:::tick-800msec
{
   trace ("800 millisecond timer");
}
