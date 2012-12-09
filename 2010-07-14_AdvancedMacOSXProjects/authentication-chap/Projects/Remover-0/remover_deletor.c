#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <stdio.h>
#include <Security/Security.h>
#include <dirent.h>

#define RIGHT "com.bignerdranch.deleteForbiddenDirectories"

void
remove_tree(char *path){
	DIR *dir;
	struct dirent *entry;
	char childPath[PATH_MAX];
	if (unlink(path) == 0)
		return;

	if (chdir(path) == -1) {
		fprintf(stderr, "Can't cd to %s", path);
		return;
	}

	// Open the directory
	dir = opendir(path);
	if (dir == NULL) {
		fprintf(stderr, "Can't open %s\n", path);
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
	rmdir(path);
}

int
main(int argc, char * const *argv)
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

	/* Read the Authorization "byte blob" from our input pipe. */
	if (fread(&extAuth, sizeof(extAuth), 1, stdin) != 1)
		exit(-1);

	/* Restore the externalized Authorization back
		to an AuthorizationRef */
	if (AuthorizationCreateFromExternalForm(&extAuth, &auth))
		exit(-1);

	// Create the rights structure
	AuthorizationItem right = { RIGHT, 0, NULL, 0 };
	AuthorizationRights rights = { 1, &right };
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights;

	fprintf(stderr, "Tool authorizing right %s for command.\n", RIGHT);

	// Check the authorization
	if (status = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, flags, NULL)) {
		fprintf(stderr, "Tool authorizing command failed authorization: %ld.\n", status);
		exit(-1);
	}
	
	// Unlink the path
	remove_tree(path);

	// Terminate
	exit(0);
}