#import <stdio.h> // for printf() 

/* compile with 
gcc -g -Wall -o long-double long-double.m 
*/ 

int main (void) 
{ 
    float thing1; 
    double thing2; 
    long double thing3; 

    thing1 = 3.14159265358979323846264338327950288419716939937510L;
    thing2 = 3.14159265358979323846264338327950288419716939937510L;
    thing3 = 3.14159265358979323846264338327950288419716939937510L;

    printf ("thing1: (%2lu) %36.35f\n", sizeof(thing1), thing1); 
    printf ("thing2: (%2lu) %36.35lf\n", sizeof(thing2), thing2); 
    printf ("thing3: (%2lu) %36.35Lf\n", sizeof(thing3), thing3); 

    return (0); 

} // main 
