// bitmask.m -- play with bitmasks

// clang -g -Weverything -Wno-unused-macros -o bitmask bitmask.m

#include <stdio.h>	// for printf

#define THING_1_MASK	1	  // 00000001
#define THING_2_MASK	2	  // 00000010
#define THING_3_MASK	4	  // 00000100
#define ALL_THINGS	(THING_1_MASK | THING_2_MASK | THING_3_MASK) // 00000111

#define ANOTHER_MASK	(1 << 5)  // 00100000
#define ANOTHER_MASK_2	(1 << 6)  // 01000000

#define ALL_ANOTHERS	(ANOTHER_MASK | ANOTHER_MASK_2)  // 01100000
#define ALL_USEFUL_BITS (ALL_THINGS | ALL_ANOTHERS)      // 01100111


static void showMaskValue (int value)
{
    printf ("\n"); // space out the output
    printf ("value %x:\n", value);
    
    if (value & THING_1_MASK) printf ("  THING_1\n");
    if (value & THING_2_MASK) printf ("  THING_2\n");
    if (value & THING_3_MASK) printf ("  THING_3\n");

    if (value & ANOTHER_MASK) printf ("  ANOTHER_MASK\n");
    if (value & ANOTHER_MASK_2) printf ("  ANOTHER_MASK\n");

    if ((value & ALL_ANOTHERS) == ALL_ANOTHERS) printf ("  ALL ANOTHERS\n");

} // showMaskValue


static int setBits (int value, int maskValue)
{
    // set a bit by just OR-ing in a value
    value |= maskValue;
    return value;
} // setBits


static int clearBits (int value, int maskValue)
{
    // to clear a bit, we and it with the complement of the mask.

    value &= ~maskValue;
    return value;

} // clearBits


int main (void) {
    int intval = 0;

    intval = setBits (intval, THING_1_MASK);	// 00000001 = 0x01
    intval = setBits (intval, THING_3_MASK);	// 00000101 = 0x05
    showMaskValue (intval);

    intval = setBits (intval, ALL_ANOTHERS);	// 01100101 = 0x65
    intval = clearBits (intval, THING_2_MASK);	// 01100101 = 0x65
    intval = clearBits (intval, THING_3_MASK);	// 01100001 = 0x61
    showMaskValue (intval);

    return 0;

} // main


