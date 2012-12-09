// my_dispatch_group_async.m -
//     Exemplifies the use of dispatch_group_enter/leave.
//gcc -std=c99 -g -Wall -Wextra my_dispatch_group_async.m -o my_dispatch_group_async

#import <dispatch/dispatch.h>
#import <stdio.h>
#import <unistd.h>

void
my_dispatch_group_async(
    dispatch_group_t group,
    dispatch_queue_t queue,
    dispatch_block_t work)
{
    dispatch_retain(group);
    dispatch_group_enter(group);

    dispatch_async(queue, ^{
        work();

        dispatch_group_leave(group);
        dispatch_release(group);
    });
}

void
dispatch_groups_async(
    dispatch_group_t groups[],
    const size_t group_count,
    dispatch_queue_t queue,
    dispatch_block_t work)
{
    for (size_t i = 0; i < group_count; ++i) {
        dispatch_retain(groups[i]);
        dispatch_group_enter(groups[i]);
    }

    dispatch_async(queue, ^{
        work();

        for (size_t i = 0; i < group_count; ++i) {
            dispatch_group_leave(groups[i]);
            dispatch_release(groups[i]);
        }
    });
}

#define NGROUPS (5UL)

int
main(void) {
    dispatch_queue_t serial = dispatch_queue_create("com.bignerdranch.serial", NULL);
    dispatch_suspend(serial);

    // Array must be static or global, otherwise newer versions of gcc complain:
    //     "cannot access copied-in variable of array type inside block"
    //
    // Starting 7 Mar 2010 with llvm-gcc revision 97931,
    // Apple decided that blocks would no longer allow
    // references to arrays that would require copying the entire array
    // into the block structure.
    // It appears they weren't always handled correctly prior to this,
    // but no error or warning was provided till this revision.
    // See <URL:http://lists.cs.uiuc.edu/pipermail/llvm-commits/Week-of-Mon-20100301/097400.html>.
    static dispatch_group_t groups[NGROUPS];
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL);
    dispatch_apply(NGROUPS, q, ^(size_t i) {
        groups[i] = dispatch_group_create();
    });

    dispatch_apply(NGROUPS, q, ^(size_t i) {
        dispatch_groups_async(groups, NGROUPS, serial, ^{
            fprintf(stderr, "Work item %zu running.\n", i);
        });
        dispatch_group_notify(groups[i], serial, ^{
            fprintf(stderr, "Group %zu complete!\n", i);
        });
    });

    dispatch_group_async(groups[0], serial, ^{
        fprintf(stderr, "Group 0-only work item has run.\n");
    });

    dispatch_resume(serial); 

    dispatch_apply(NGROUPS, q, ^(size_t i) {
        dispatch_release(groups[i]);
    });

    // Wait for serial queue to clear before exiting.
    dispatch_sync(serial, ^{});
    return 0;
}
// vi: set ts=4 sw=4 et:
