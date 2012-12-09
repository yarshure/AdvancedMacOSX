#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <stdio.h>
#include <Security/Security.h>
#include <dirent.h>

#define RIGHT "com.bignerdranch.remover.deleteforbiddendirectories"

// remove_tree recursively removes a directory and its contents
void remove_tree(const char *path){
    DIR *dir;
    struct dirent *entry;
    char childPath[PATH_MAX];
    if (unlink(path) == 0)
        return;
    
    // Open the directory
    dir = opendir(path);
    if (!dir) {
        fprintf(stderr, "Cannot open %s\n", path);
        return;
    }
    
    // Read all the entries
    while (entry = readdir(dir)) {
        // Skip . and ..
        if (strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        if (strcmp(entry->d_name, ".") == 0) {
            continue;
        }
        snprintf(childPath, PATH_MAX, "%s/%s", path, entry->d_name);
        remove_tree(childPath);
    }
    
    // Close the directory
    closedir(dir);
    
    // Delete the now-empty directory
    rmdir(path);
}

int main(int argc, char *argv[])
{
    OSStatus status;
    AuthorizationRef auth;
    char *path;
    
    AuthorizationExternalForm extAuth;
    
    // Is this process running as root?
    if (geteuid() != 0) {
        fprintf(stderr, "Not running as root\n");
        exit(-1);
    }
    
    // Was there one argument?
    if (argc != 2) {
        fprintf(stderr, "Usage: remove_deletor <dir>\n");
        exit(-1);
    }
    
    // Get the path
    path = argv[1];
    
    // Read the Authorization data from our input pipe.
    if (fread(&extAuth, sizeof(extAuth), 1, stdin) != 1) {
        fprintf(stderr, "Could not read authorization\n");
        exit(-1);
    }
    
    // Restore the externalized Authorization back 
    // to an AuthorizationRef
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
        fprintf(stderr, 
                "Tool authorizing command failed authorization: %ld.\n", 
                status);
        exit(-1);
    }
    
    // Unlink the path
    remove_tree(path);
    
    // Terminate
    exit(0);
}