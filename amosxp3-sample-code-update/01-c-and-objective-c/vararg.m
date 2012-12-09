// vararg.m -- use varargs to sum a list of numbers

// clang -g -Weverything -o vararg vararg.m


#import <stdio.h>
#import <stdarg.h>

// sum all the integers passed in.  Stopping if it's zero

static int addemUp (int firstNum, ...) {
    va_list args;

    int sum = firstNum;
    int number;

    va_start (args, firstNum);
    while (1) {
	number = va_arg (args, int);
	sum += number;
	if (number == 0) {
	    break;
	}
    }
    va_end (args);

    return sum;

} // addemUp


int main (void) {
    int sumbody;

    sumbody = addemUp (1, 2, 3, 4, 5, 6, 7, 8, 9, 0);
    printf ("sum of 1..9 is %d\n", sumbody);

    sumbody = addemUp (1, 3, 5, 7, 9, 11, 0);
    printf ("sum of odds from 1..11 is %d\n", sumbody);

    return 0;

} // main
