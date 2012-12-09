// additem.m -- add a new item to the keychain

// clang -g -Weverything -framework Security -o additem additem.m

#import <Security/Security.h>

#include <stdio.h> // for printf()

int main (void) {
    SecKeychainAttribute attributes[2];
    attributes[0].tag = kSecAccountItemAttr;
    attributes[0].data = "fooz";
    attributes[0].length = 4;
    
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[1].data = "I seem to be a verb";
    attributes[1].length = 19;

    SecKeychainAttributeList list;
    list.count = 2;
    list.attr = attributes;

    SecKeychainItemRef item;
    OSStatus status = SecKeychainItemCreateFromContent
        (kSecGenericPasswordItemClass, &list, 
         5, "budda", NULL, NULL, &item);
    
    if (status != 0) {
        printf("Error creating new item: %d\n", (int)status);
    }
    return EXIT_SUCCESS;

} // main
