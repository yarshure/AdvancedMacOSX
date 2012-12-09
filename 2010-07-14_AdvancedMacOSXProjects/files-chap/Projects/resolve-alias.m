// resolve-alias.m - Resolve a Finder alias file.
//clang -g -std=c99 -Wall -Wextra -framework CoreServices resolve-alias.m -o resolve-alias

#import <CoreServices/CoreServices.h>
#import <sysexits.h>  // EX_USAGE, EX_OK

#define DEBUG (FALSE)
void Usage(void);

int
main(int argc, char *argv[]) {
    if (argc < 2) {
        Usage();
        exit(EX_USAGE);
    }

    for (int i = 1; i < argc; ++i) {
        FSRef file;
        OSStatus err = FSPathMakeRef((UInt8 *)argv[i], &file, NULL);
        if (err) {
            fprintf(stderr, "%s: *** %s: %s\n", getprogname(), argv[i],
                    GetMacOSStatusCommentString(err));
            continue;
        }

        UInt32 maxPathSize = 256;
        UInt8 *path = malloc(maxPathSize);

        const Boolean resolveAliasChains = FALSE;
        Boolean isAlias = TRUE;
        Boolean firstFile = TRUE;
        while (isAlias) {
            Boolean isFolder = FALSE;
            err = FSIsAliasFile(&file, &isAlias, &isFolder);
            if (err) {
                fprintf(stderr, "%s: *** %s: %s\n", getprogname(), argv[i],
                        GetMacOSStatusCommentString(err));
                break;
            }

            Boolean wasAliased = FALSE;
            if (firstFile) firstFile = FALSE;
            else {
                err = FSResolveAliasFile(
                          &file,
                          resolveAliasChains,
                          &isFolder,
                          &wasAliased);
                if (err) {
                    fprintf(stderr, "%s: *** %s: %s\n", getprogname(), argv[i],
                            GetMacOSStatusCommentString(err));
                    break;
                }
            }

            while ((err = FSRefMakePath(&file, path, maxPathSize))) {
                UInt32 tempSize = 2 * maxPathSize;
                UInt8 *tempPath = realloc(path, tempSize);
                if (!tempPath) {
                    fprintf(stderr, "%s: %s\n", getprogname(), strerror(errno));
                    break;
                }
                path = tempPath;
                maxPathSize = tempSize;
            }
#if DEBUG
            fprintf(stderr, "%s:\n\tisFolder? %s\n\tisAlias? %s\n\twasAliased? %s\n",
                    path, isFolder? "TRUE" : "FALSE",
                    isAlias? "TRUE" : "FALSE",
                    wasAliased? "TRUE" : "FALSE");
#endif

            if (err) {
                fprintf(stdout, "%s (%s)\n", path,
                        GetMacOSStatusCommentString(err));
                fprintf(stderr, "%s: *** %s: %s\n", getprogname(), path,
                        GetMacOSStatusCommentString(err));
                break;
            }

            if (isAlias) {
                fprintf(stdout, "%s -> \n", path);
            } else if (isFolder) {
                fprintf(stdout, "%s (folder)\n", path);
            } else {
                fprintf(stdout, "%s\n", path);
            }
        }
        free(path), maxPathSize = 0;
    }
    return EX_OK;
}

void
Usage(void) {
    fprintf(stderr, "Usage: %s FILE [FILE...]\n\tResolves Finder aliases.\n",
            getprogname());
}

// vi: set ts=4 sw=4 et filetype=objc syntax=objc:
