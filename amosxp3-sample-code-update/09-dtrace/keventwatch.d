#!/usr/sbin/dtrace -s

/* show the kevent() calls made by Directory Services and dirwatcher.
 * Run with
   sudo dtrace -s keventwatch.d
*/

syscall::kevent:entry
/execname == "dirwatcher" || execname == "DirectoryServic"/
{
    printf("%s called kevent()", execname);
}
