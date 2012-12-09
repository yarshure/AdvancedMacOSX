// popen.m -- demonstrate popen().  This does the
//            equivalent of 
//            cat /usr/share/dict/words | tr '[:lower:]' '[:upper:]' | head -13
//            but we're doing the cat and head parts ourselves

// clang -g -Weverything -o popen popen.m


#import <stdio.h>	// for popen, printf
#import <stdlib.h>	// for EXIT_SUCCESS

#define NUM_LINES 13
#define BUFSIZE   4096

int main (void) {
    FILE *dictionary = NULL;
    FILE *pipeline = NULL;
    int result = EXIT_FAILURE;

    dictionary = fopen ("/usr/share/dict/words", "r");
    if (dictionary == NULL) {
	fprintf (stderr, "could not open /usr/share/dict/words\n");
	goto bailout;
    }

    // BiDi pipes from popen are buffered, so both programs need to flush buffers.
    // fputs() does that for us on a newline, but we have to tell 'tr' to run
    // unbuffered.  This limits the use bidirectional pipes to programs that
    // flush buffers.

    pipeline = popen ("tr -u '[:lower:]' '[:upper:]'", "r+");

    if (pipeline == NULL) {
	fprintf (stderr, "error popening pipeline\n");
	goto bailout;
    }

    for (int i = 0; i < NUM_LINES; i++) {
        char originalWord[BUFSIZE], translatedWord[BUFSIZE];

	// get a word from the dictionary
	if (fgets (originalWord, BUFSIZE, dictionary) == NULL) {
	    fprintf (stderr, "could not read from dictionary stream\n");
	    goto bailout;
	}

	// stuff it into the pipeline
	if (fputs (originalWord, pipeline) == EOF) {
	    fprintf (stderr, "could not write to pipeline\n");
	    goto bailout;
        }

	// and pick off the translated value
	if (fgets (translatedWord, BUFSIZE, pipeline) == NULL) {
	    fprintf (stderr, "could not read from pipeline\n");
	    goto bailout;
	}

	// and tell the user
	printf ("%s -> %s\n", originalWord, translatedWord);
    }

    result = EXIT_SUCCESS;

bailout:
	
    if (dictionary != NULL) fclose (dictionary);
    if (pipeline != NULL) pclose (pipeline);
    
    return (result);

} // main

