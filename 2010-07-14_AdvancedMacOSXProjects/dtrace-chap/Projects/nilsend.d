/* Trace nil-message sends in objective-C.
   Thanks to Bill Bumgardner:
   <http://www.friday.com/bbum/2008/01/03/objective-c-using-dtrace-to-trace-messages-to-nil/>
   Run with:
   sudo dtrace -qs nilsend.d $pid
*/

pid$1::objc_msgSend:entry
/arg0 == 0/
{
    printf("[<nil> %s]", copyinstr(arg1));
    ustack();
}
