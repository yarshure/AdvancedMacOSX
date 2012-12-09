// dumpem.m -- look into the keychain

// clang -g -Weverything -Wno-deprecated-declarations -framework Security -framework CoreFoundation -o dumpem-1 dumpem-1.m

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

#import <stdlib.h>	// for EXIT_SUCCESS
#import <stdio.h>	// for printf() and friends
#import <string.h>	// for strncpy

int main (int argc, char *argv[]) {
    if (argc != 2) {
        printf ("usage: %s account-name\n", argv[0]);
        return EXIT_FAILURE;
    }

    // Build an attribute list with just one attribute.
    SecKeychainAttribute attribute;
    attribute.tag = kSecAccountItemAttr;
    attribute.length = (UInt32)strlen(argv[1]);
    attribute.data = argv[1];

    // Make a list to point to this new attribute.
    SecKeychainAttributeList list;
    list.count = 1;
    list.attr = &attribute;

    // Create a search handle with the attribute list.
    SecKeychainSearchRef search;
    OSStatus result = SecKeychainSearchCreateFromAttributes 
	(NULL, kSecGenericPasswordItemClass, &list, &search);

    if (result != noErr) {
	printf ("result %d from "
		"SecKeychainSearchCreateFromAttributes\n",
		result);
    }

    // Iterate over the search results
    int count = 0;
    SecKeychainItemRef item;
    while (SecKeychainSearchCopyNext (search, &item) != errSecItemNotFound) {
	CFRelease (item);
	count++;
    }

    printf ("%d items found\n", count);
    CFRelease (search);

    return EXIT_SUCCESS;

} // main

