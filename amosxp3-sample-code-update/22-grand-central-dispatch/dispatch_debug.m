// dispatch_debug.m - Dump output from dispatch_debug.

// clang -g -Weverything dispatch_debug.m -o dispatch_debug

#import <dispatch/dispatch.h>
#import <fcntl.h>  // open()
#import <syslog.h> // for openlog()

int main (void) {
    // Log syslog messages to stderr.
    openlog ("com.bignerdranch.dispatch_debug",
             LOG_PERROR, LOG_USER);

    dispatch_queue_t global_queue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0UL);
    dispatch_queue_t example_queue =
        dispatch_queue_create("com.bignerdranch.exampleq", NULL);

    dispatch_group_t dispatch_group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0L);

    int fd = open("/var/tmp", O_RDONLY);

    dispatch_source_t ds_vnode =
        dispatch_source_create (DISPATCH_SOURCE_TYPE_VNODE,
                                (uintptr_t)fd, 
                                DISPATCH_VNODE_LINK | DISPATCH_VNODE_ATTRIB,
                                global_queue);
    dispatch_resume(ds_vnode);

    dispatch_source_t ds_data_or =
        dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_OR,
                               0, 0, example_queue);
    // leave it suspended
    dispatch_source_merge_data (ds_data_or, true);


#define _(x) ((dispatch_object_t)(x))
    dispatch_object_t dispatch_objects[] = {
        _(global_queue),
        _(example_queue),
        _(dispatch_group),
        _(semaphore),
        _(ds_vnode), 
        _(ds_data_or),
    };
#undef _

    const char *descriptions[] = {
        "global queue", "serial queue",
        "group", "semaphore",
        "vnode source", "data-or source",
    };

#define COUNT_OF(xs) (sizeof((xs)) / sizeof(*(xs)))

    // sanity check that number of of descriptiosn is the same as
    // number of of dispatch objects
    typedef char SAME_COUNT[COUNT_OF(dispatch_objects) 
                            == COUNT_OF(descriptions)? 1 : -1];

    const char *const *desc = descriptions;
    for (dispatch_object_t *scan = dispatch_objects, 
             *endp = &dispatch_objects[COUNT_OF(dispatch_objects)];
         scan < endp; ++scan) {
         dispatch_debug (*scan, "%s example", *desc++);
    }

    closelog();

    return 0;

} // main
