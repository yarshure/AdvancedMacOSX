/* Show procoess launches across the system.
   Run with
   sudo dtrace -s execs.d
*/

proc:::exec-success
{
    trace(execname);
}
