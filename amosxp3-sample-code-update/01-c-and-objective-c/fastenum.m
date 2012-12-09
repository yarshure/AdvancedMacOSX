// fastenum.m -- fast enumeration over two collections : a C array,
//  and an infinite sequence.

// clang -g -Weverything -Wno-unused-parameter -framework Foundation -o fastenum fastenum.m

#import <Foundation/Foundation.h>

@interface CArray : NSObject <NSFastEnumeration> {
    NSString **_strings;
    NSUInteger _stringCount;
    unsigned long _mutations;
}

- (void) setStrings: (NSString *)string, ... NS_REQUIRES_NIL_TERMINATION;

@end // CArray


@implementation CArray

- (void) cleanUpStrings {
    _mutations++;
    for (NSUInteger i = 0; i < _stringCount; i++) {
        [_strings[i] release];
    }

    free (_strings);
    _strings = NULL;
    _stringCount = 0;

} // cleanUpStrings


- (void) dealloc {
    [self cleanUpStrings];
    [super dealloc];
} // dealloc


- (void) setStrings: (NSString *)string, ... {
    [self cleanUpStrings];

    va_list args;
    va_start (args, string);

    while (string != nil) {
        _stringCount++;
        _strings = realloc (_strings, sizeof(NSString *) * _stringCount);
        _strings[_stringCount - 1] = [string retain];
        
        string = va_arg (args, NSString *);
    }

    va_end (args);

} // setStrings


- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state
                                   objects: (id *) stackbuf 
                                     count: (NSUInteger) len {
    if (state->state == 0) {
        // first call, do initializations
        state->state = 1;
        state->mutationsPtr = &_mutations;
        state->itemsPtr = _strings;

        return (_stringCount);

    } else {
        // we returned everything the first time through, so we're done
        return 0;
    }

} // countByEnumeratingWithState

@end // CArray


// --------------------------------------------------

@interface FibonacciSequence : NSObject <NSFastEnumeration>
@end // FibonacciSequence


@implementation FibonacciSequence

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state
                                   objects: (id *) stackbuf 
                                     count: (NSUInteger) len {
    assert(len >= 2); // because we pre-populate two values on first-call
    id *scan, *stop;

    if (state->state == 0) {
        // First call, do initializations.
        state->state = 1;
        state->mutationsPtr = (unsigned long *)self; // not applicable
        state->itemsPtr = stackbuf;
        
        // extra[0] has the N - 2 value, extra[1] has the N - 1 value
        // seed with correct values
        state->extra[0] = 1;
        state->extra[1] = 1;

        // Fill in the first two values.
        state->itemsPtr[0] = [NSNumber numberWithUnsignedLong: state->extra[0]];
        state->itemsPtr[1] = [NSNumber numberWithUnsignedLong: state->extra[1]];

        // Tweak the scanning pointers because we've already filled
        // in the first two slots.
        scan = &state->itemsPtr[2];
        stop = &state->itemsPtr[0] + len;

    } else {
        // Otherwise we're in the Pink, and do normal processing for
        // all of the itemPtrs.
        scan = &state->itemsPtr[0];
        stop = &state->itemsPtr[0] + len;
    }

    while (scan < stop) {
        // Do the Fibonacci algorithm.
        NSUInteger value = state->extra[0] + state->extra[1];
        state->extra[0] = state->extra[1];
        state->extra[1] = value;

        // Populate the fast enum item pointer.
        *scan = [NSNumber numberWithUnsignedLong: value];

        // and then scoot over to the next value
        scan++;
    }

    // Always fill up their stack buffer.
    return len;

} // countByEnumeratingWithState

@end // FibonacciSequence


int main (void) {
    [[NSAutoreleasePool alloc] init];

    CArray *carray = [[CArray alloc] init];
    [carray setStrings: @"I", @"seem", @"to", @"be", @"a", @"verb", nil];

    for (NSString *string in carray) {
        NSLog (@"%@", string);
    }

    FibonacciSequence *fibby = [[FibonacciSequence alloc] init];

    int boredom = 0;
    for (NSNumber *number in fibby) {
        NSLog (@"%@", number);
        if (boredom++ > 90) {
            break;
        }
    }

    return (0);

} // main
