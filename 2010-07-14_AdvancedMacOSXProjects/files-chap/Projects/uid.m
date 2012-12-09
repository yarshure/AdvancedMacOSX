// uid.m -- experiment with user and group ids.
//          run as normal, then change this to be suid, and run again

/* compile with 
gcc -g -Wall -o uid uid.m
*/

#import <sys/types.h>   // for struct group/struct passwd
#import <grp.h>         // for getgrgid
#import <pwd.h>         // for getpwuid
#import <stdio.h>       // printf and friends
#import <stdlib.h>      // EXIT_SUCCESS
#import <unistd.h>      // for getuid(), etc


int main (int argc, char *argv[]) {
    uid_t user_id = getuid ();
    uid_t effective_user_id = geteuid ();

    gid_t group_id = getgid ();
    gid_t effective_group_id = getegid ();

    struct passwd *user = getpwuid (user_id);
    printf ("real user ID is '%s'\n", user->pw_name);

    user = getpwuid (effective_user_id);
    printf ("effective user ID is '%s'\n", user->pw_name);

    struct group *group = getgrgid (group_id);
    printf ("real group is '%s'\n", group->gr_name);

    group = getgrgid (effective_group_id);
    printf ("effective group is '%s'\n", group->gr_name);

    exit (EXIT_SUCCESS);

} // main
