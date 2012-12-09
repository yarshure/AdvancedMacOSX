// BundlePrinter.h -- protocol for BundlePrinter plugins to use

@protocol BundlePrinterProtocol

+ (BOOL) activate;
+ (void) deactivate;

- (NSString *) message;

@end
