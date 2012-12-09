// dispatch_debug.m - Dump output from dispatch_debug.
//gcc -std=c99 -g -Wall -Wextra dispatch_debug.m -o dispatch_debug

#import <dispatch/dispatch.h>
#import <syslog.h>
#import <fcntl.h>  // open(2)

int
main(void) {
    // Log syslog messages to stderr.
    openlog("com.bignerdranch.dispatch_debug",
            LOG_PERROR, LOG_USER);

    dispatch_queue_t gq = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL);
    dispatch_queue_t dq = dispatch_queue_create("com.bignerdranch.exampleq", NULL);

    dispatch_group_t dg = dispatch_group_create();
    dispatch_semaphore_t dsema = dispatch_semaphore_create(0L);

    int fd = open("/var/tmp", O_RDONLY);
    dispatch_source_t ds_vnode = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_VNODE,
        fd, DISPATCH_VNODE_LINK | DISPATCH_VNODE_ATTRIB, gq);
    dispatch_resume(ds_vnode);

    dispatch_source_t ds_dataor = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_DATA_OR,
        0, 0, dq);
    // leave it suspended
    dispatch_source_merge_data(ds_dataor, true);


    #define DO_CAST(x) ((dispatch_object_t)(x))
    dispatch_object_t dos[] = {
        DO_CAST(gq), DO_CAST(dq),
        DO_CAST(dg), DO_CAST(dsema),
        DO_CAST(ds_vnode), DO_CAST(ds_dataor),
    };
    const char *descs[] = {
        "global queue", "serial queue",
        "group", "semaphore",
        "vnode source", "data-or source",
    };

    #define COUNT_OF(xs) (sizeof((xs)) / sizeof(*(xs)))
    typedef char SAME_COUNT[COUNT_OF(dos) == COUNT_OF(descs)? 0 : -1];

    const char *const *desc = descs;
    for (dispatch_object_t *dop = dos, *endp = &dos[COUNT_OF(dos)];
         dop < endp; ++dop) {
         dispatch_debug(*dop, "%s example", *desc++);
    }

    closelog();
    return 0;
}
// vi: set ts=4 sw=4 et:
