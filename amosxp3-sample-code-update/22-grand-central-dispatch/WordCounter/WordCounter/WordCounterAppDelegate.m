#import "WordCounterAppDelegate.h"


@interface WordCounterAppDelegate ()
- (void) getWordCount: (NSUInteger *) count
       andFrequencies: (NSCountedSet **) frequencies
            forString: (NSString *) string;
@end // extension


@implementation WordCounterAppDelegate

@synthesize window = _window;
@synthesize wordsView = _wordsView;
@synthesize countLabel = _countLabel;
@synthesize uniqueLabel = _uniqueLabel;
@synthesize countButton = _countButton;
@synthesize spinner = _spinner;


// Return two values from a function.


- (void) getWordCount: (NSUInteger *) count
       andFrequencies: (NSCountedSet **) frequencies
            forString: (NSString *) string {
    NSScanner *scanner = [NSScanner scannerWithString: string];
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    *count = 0;
    *frequencies = [NSCountedSet set];

    NSString *word;
    while ([scanner scanUpToCharactersFromSet: whiteSpace  intoString: &word]) {
        [*frequencies addObject: [word lowercaseString]];
        (*count)++;
    }

    sleep (2); // Machines these days are too dang fast!

} // getWordCount


#define GCD_COUNT 1

#if GCD_COUNT

- (void) disableEverything {
    // NSTextView doesn't have an enabled binding, so we'll just do it all here.
    [self.wordsView setEditable: NO];
    [self.countButton setEnabled: NO];
    [self.spinner setHidden: NO];
    [self.spinner startAnimation: self];
} // disableEverything


- (void) enableEverything {
    [self.wordsView setEditable: YES];
    [self.countButton setEnabled: YES];
    [self.spinner stopAnimation: self];
    [self.spinner setHidden: YES];
} // enableEverything


#if 1
- (IBAction) count: (id) sender {

    [self disableEverything];

    dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSUInteger count;
            NSCountedSet *frequencies;

            [self getWordCount: &count
                  andFrequencies: &frequencies
                  forString: self.wordsView.string];

            dispatch_async (dispatch_get_main_queue(), ^{
                    NSString *labelString =
                        [NSString stringWithFormat: @"Word count: %lu", count];
                    [self.countLabel setStringValue: labelString];

                    labelString =
                        [NSString stringWithFormat: @"Unique words: %lu",
                                  frequencies.count];

                    [self.uniqueLabel setStringValue: labelString];
                    [self enableEverything];
                });
        });

} // count
#endif


#if 0

- (IBAction) count: (id) sender {

    [self disableEverything];

    NSUInteger count;
    NSCountedSet *frequencies;

    [self getWordCount: &count
          andFrequencies: &frequencies
          forString: self.wordsView.string];

    NSString *labelString =
        [NSString stringWithFormat: @"Word count: %lu", count];
    [self.countLabel setStringValue: labelString];

    labelString =
        [NSString stringWithFormat: @"Unique words: %lu",
                  frequencies.count];

    [self.uniqueLabel setStringValue: labelString];
    [self enableEverything];

} // count

#endif

#else

- (IBAction) count: (id) sender {
    NSUInteger count;
    NSCountedSet *frequencies;

    [self getWordCount: &count
          andFrequencies: &frequencies
          forString: self.wordsView.string];

    NSString *labelString = [NSString stringWithFormat: @"Word count: %lu", count];
    [self.countLabel setStringValue: labelString];

    labelString = [NSString stringWithFormat: @"Unique words: %lu",
                            frequencies.count];
    [self.uniqueLabel setStringValue: labelString];

} // count


#endif


@end // WordCounterAppDelegate

