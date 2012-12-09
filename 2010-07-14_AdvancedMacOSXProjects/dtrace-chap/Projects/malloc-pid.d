/* show the malloc() calls made by the process, whose pid is provided as an 
   argument to the dtrace command.
   Run with:
   sudo dtrace -q -s malloc-pid.d 1313
   Where 1313 is some process ID
*/

pid$1:libSystem.B.dylib:malloc:entry
{
    printf("malloc of %d bytes for %s", arg0, execname);
}
