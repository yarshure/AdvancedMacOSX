// const.m -- play with const declarations

/* compile with:  (will actually generate errors.  that's ok)
clang -g -Weverything -o const const.m
*/

int main (void) {

    const int i = 23;
    i = 24; // error: assignment of read-only variable 'i'

    // pointer to const
    const char *string = "bork"; // the data pointed to by string is const
    string = "greeble"; // this is ok
    string[0] = 'f'; // error: assignment of read-only location

    // const pointer
    char * const string2 = "bork";  // the pointer itself is const
    string2 = "greeble"; // error: assignment of read-only variable 'string2'
    string2[0] = 'f'; // this is ok

    // const pointer to const
    const char * const string3 = "bork"; // pointer and pointee are const
    string3 = "greeble"; // error: assignment of read-only variable 'string3'
    string3[0] = 'f'; // error: assignment of read-only location

    return (0);

} // main
