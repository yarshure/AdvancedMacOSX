/* show the BEGIN and END providers
  run with:
  sudo dtrace -s begin-end.d
*/


BEGIN
{
  trace("begin the beguine");
  exit(0);
}

END
{
  trace("that's all, folks...");
}
