#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <stdio.h>
#include <Security/Security.h>

#define RIGHT "com.bignerdranch.remover.readforbiddendirectories"

int
main(int argc, char *argv[])
{
    OSStatus status;
    AuthorizationRef auth;
    char *path;
    struct stat statbuf;
    char *typeAsString;
    
    AuthorizationExternalForm extAuth;
    
    // Is this process running as root?
    if (geteuid() != 0) {
        fprintf(stderr, "Not running as root\n");
        exit(-1);
    }
    
    // Was there one argument?
    if (argc != 2) {
        fprintf(stderr, "Usage: remove_statter <dir>\n");
        exit(-1);
    }
    
    // Get the path
    path = argv[1];
    
    // Read the Authorization "byte blob" from our input pipe. 
    if (fread(&extAuth, sizeof(extAuth), 1, stdin) != 1) {
        fprintf(stderr, "Unable to read authorization\n");
        exit(-1);
    }
    
    // Restore the externalized Authorization back to an AuthorizationRef 
        if (AuthorizationCreateFromExternalForm(&extAuth, &auth)) {
            fprintf(stderr, "Unable to parse authorization data\n");
            exit(-1);
        }
    
    // Create the rights structure
    AuthorizationItem right = { RIGHT, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &right };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | 
        kAuthorizationFlagExtendRights;
    
    fprintf(stderr, "Tool authorizing right %s for command.\n", RIGHT);
    
    // Check the authorization
    if (status = AuthorizationCopyRights(auth, &rights, 
                                         kAuthorizationEmptyEnvironment, flags, NULL)) {
        fprintf(stderr, "Tool failed authorization: %ld.\n", 
                status);
        exit(-1);
    }
    // Stat the path
    if (stat(path, &statbuf)) {
        fprintf(stderr, "Unable to stat %s", path);
        exit(-1);
    }
    
    // Write out stat info
    if (S_ISDIR(statbuf.st_mode))
        typeAsString = "NSFileTypeDirectory";
    else
        typeAsString = "NSFileTypeRegular";
    
    fprintf(stdout, "%s\n%lu", typeAsString, (unsigned long)statbuf.st_size);
    
    
    
    
    fclose(stdout);
    
    // Terminate
    exit(0);
}