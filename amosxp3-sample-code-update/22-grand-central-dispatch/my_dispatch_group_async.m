// my_dispatch_group_async.m -- play with dispatch_group_enter/leave.

// clang -g -Weverything  my_dispatch_group_async.m -o my_dispatch_group_async

#import <dispatch/dispatch.h>
#import <stdio.h>
#import <unistd.h>


#if 0
// How you'd implement an async dispatch to a group.
static void my_dispatch_group_async (dispatch_group_t group,
                                     dispatch_queue_t queue,
                                     dispatch_block_t workblock) {
    dispatch_retain (group);
    dispatch_group_enter (group);

    dispatch_async (queue, ^{
        workblock ();

        dispatch_group_leave (group);
        dispatch_release (group);
    });
}
#endif


static void dispatch_groups_async (dispatch_group_t groups[],
                                   const size_t group_count,
                                   dispatch_queue_t queue,
                                   dispatch_block_t workblock) {
    for (size_t i = 0; i < group_count; ++i) {
        dispatch_retain (groups[i]);
        dispatch_group_enter (groups[i]);
    }

    dispatch_async(queue, ^{
        workblock ();

        for (size_t i = 0; i < group_count; ++i) {
            dispatch_group_leave (groups[i]);
            dispatch_release (groups[i]);
        }
    });
}

#define NGROUPS 5

int main (void) {
    dispatch_queue_t serial_queue = dispatch_queue_create("com.bignerdranch.serial", NULL);

    dispatch_suspend(serial_queue);

    // Array must be static or global (effectively the same thing), 
    // otherwise the compiler complains "cannot access copied-in variable of
    // array type inside block"

    static dispatch_group_t groups[NGROUPS];
    dispatch_queue_t global_queue = 
        dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL);

    dispatch_apply (NGROUPS, global_queue, ^(size_t i) {
        groups[i] = dispatch_group_create ();
    });

    dispatch_apply (NGROUPS, global_queue, ^(size_t i) {
        dispatch_groups_async (groups, NGROUPS, serial_queue, ^{
            fprintf(stderr, "Work item %zu running.\n", i);
        });
        dispatch_group_notify (groups[i], serial_queue, ^{
            fprintf(stderr, "Group %zu complete!\n", i);
        });
    });

    dispatch_group_async (groups[0], serial_queue, ^{
        fprintf(stderr, "Group 0-only work item has run.\n");
    });

    dispatch_resume (serial_queue); 

    dispatch_apply (NGROUPS, global_queue, ^(size_t i) {
        dispatch_release (groups[i]);
    });

    // Wait for serial_queue to clear before exiting.
    dispatch_sync (serial_queue, ^{});

    return 0;

} // main
