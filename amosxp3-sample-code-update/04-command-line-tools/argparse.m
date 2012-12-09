// argparse.m -- using getopt_long to parse arguments

/* compile with
clang -Weverything -g -o argparse argparse.m
*/

#import <getopt.h>  // for getopt_long()
#import <stdio.h>   // for printf()
#import <stdlib.h>  // for EXIT_SUCCESS

static const char *optstring = "gf:c::o";

static int thing1, thing2, thing3;

static struct option longopts[] = {
    { "filename",  required_argument,  NULL,    'f' },
    { "cattoy",    optional_argument,  NULL,    'c' },
    { "oop",       no_argument,        NULL,    'o' },
    { "thing1",    no_argument,        &thing1,  1 },
    { "thing2",    no_argument,        &thing2,  2 },
    { "thing3",    no_argument,        &thing3,  3 },
    {  NULL,       0,                  NULL,     0 }
};


int main (int argc, char *argv[]) {
    int ch;

    while ((ch = getopt_long(argc, argv,
                             optstring, longopts, NULL)) != -1) {
        switch (ch) {
        case 'g':
            puts ("  greeble!");
            break;
        case 'f':
            printf ("  file name is %s\n", optarg);
            break;
        case 'c':
            printf ("  cat toy is %s\n",
                    (optarg == NULL) ? "string" : optarg);
            break;
        case 'o':
            puts ("  oop!");
            break;
        case 0:
            puts ("  getopt_long set a variable");
            break;
        case ':': 
            printf ("  missing required argument");
            break;
        case '?': 
            printf ("  oops, unknown option: %s\n", argv[optind - 1]);
            break;
        }
    }

    // See if the thing variables got manipulated.
    printf  ("thing1: %d  thing2: %d  thing3: %d\n",
             thing1, thing2, thing3);

    // Mop-up any remaining arguments.
    argc -= optind;
    argv += optind;

    if (argc > 0) {
        puts ("additional trailing arguments:");
        for (int i = 0; i < argc; i++) {
            printf ("  %s\n", argv[i]);
        }
    }
    return EXIT_SUCCESS;
}  // main
