// popen.m -- demonstrate popen().  This does the
//            equivalent of 
//            cat /usr/share/dict/words | tr '[:lower:]' '[:upper:]' | head -13
//            but we're doing the cat and head parts ourselves

/* compile with
cc -g -Wmost -o popen popen.m
*/

#import <stdio.h>	// for popen, printf
#import <stdlib.h>	// for EXIT_SUCCESS

#define NUM_LINES 13
#define BUFSIZE   4096

int main (int argc, char *argv[])
{
    FILE *dictionary = NULL;
    FILE *pipeline = NULL;
    int result = EXIT_FAILURE;
    char originalWord[BUFSIZE], translatedWord[BUFSIZE];
    int i;

    dictionary = fopen ("/usr/share/dict/words", "r");
    if (dictionary == NULL) {
	fprintf (stderr, "could not open /usr/share/dict/words\n");
	goto bailout;
    }

    // !!! looks like the bidirectional pipes are broken, even though the
    // !!! man page says they work.  Thus scuttling this whole sample

    pipeline = popen ("tr '[:lower:]' '[:upper:]'", "r+");

    if (pipeline == NULL) {
	fprintf (stderr, "error popening pipeline\n");
	goto bailout;
    }

    for (i = 0; i < NUM_LINES; i++) {
	// get a word from the dictionary
	if (fgets (originalWord, BUFSIZE, dictionary) == NULL) {
	    fprintf (stderr, "could not read from dictionary stream\n");
	    goto bailout;
	}

	// stuff it into the pipeline
	if (fputs (originalWord, pipeline) == NULL) {
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
	
    if (dictionary != NULL) {
	fclose (dictionary);
    }
    if (pipeline != NULL) {
	pclose (pipeline);
    }
    
    return (result);


} // main

