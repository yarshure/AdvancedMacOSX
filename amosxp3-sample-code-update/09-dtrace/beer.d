/* sings a pretty song.
  run with:
  sudo dtrace -qs beer.d
*/

int bottles; /* optional */

BEGIN
{
    bottles = 99;
}

profile:::tick-1sec
{
    printf ("%d bottles of beer on the wall\n", bottles);
    printf ("%d bottles of beer.\n", bottles);
    printf ("take one down, pass it around\n");
    bottles--;
    printf ("%d bottles of beer on the wall\n\n", bottles);
}

END
{
    printf ("that's all, folks...");
}
