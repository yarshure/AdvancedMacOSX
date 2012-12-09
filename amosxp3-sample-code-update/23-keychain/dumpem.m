// dumpem.m -- look into the keychain

// clang -g -Weverything -Wno-deprecated-declarations -framework Security -framework Foundation -o dumpem dumpem.m

#import <Security/Security.h>
#import <Foundation/Foundation.h>

#import <stdlib.h>      // for EXIT_SUCCESS
#import <stdio.h>       // for printf() and friends
#import <string.h>      // for strncpy

// Given a carbon-style four character code, make a C string that can
// be given to printf.
static const char *fourByteCodeString (UInt32 code) {
    // C string that gets returned.  Definitely not thread safe.
    static char string[5];
    char *codePtr = (char *)(&code);

    string[0] = codePtr[3];
    string[1] = codePtr[2];
    string[2] = codePtr[1];
    string[3] = codePtr[0];
    string[4] = '\000';

    return string;

} // fourByteCodeString


// Display each attribute in the list.
static void showList (SecKeychainAttributeList list) {
    for (UInt32 i = 0; i < list.count; i++) {
        SecKeychainAttribute attr = list.attr[i];

        char buffer[1024];
        if (attr.length < sizeof(buffer)) {
            // make a copy of the data so we can stick on
            // a trailing zero byte
            strncpy (buffer, attr.data, attr.length);
            buffer[attr.length] = '\0';

            printf ("\t%d: '%s' = \"%s\"\n", 
                    i, fourByteCodeString(attr.tag), buffer);
        } else {
            printf ("attribute %s is more than 1K\n",
                    fourByteCodeString(attr.tag));
        }
    }

} // showList


// Display a keychain item's info.
static void dumpItem (SecKeychainItemRef item, bool displayPassword) {
    // Build the attributes we're interested in examining.
    SecKeychainAttribute attributes[3];
    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecModDateItemAttr;

    SecKeychainAttributeList list;
    list.count = 3;
    list.attr = attributes;

    // Get the item's information, including the password.
    UInt32 length = 0;
    char *password = NULL;
    OSStatus result;
    if (displayPassword) {
        result = SecKeychainItemCopyContent (item, NULL, &list, &length, 
                                             (void **)&password);
    } else {
        result = SecKeychainItemCopyContent (item, NULL, &list, NULL, NULL);
    }

    if (result != noErr) {
        printf ("dumpItem: error result of %d\n", result);
        return;
    }

    if (password != NULL) {
        // Copy the password into a buffer and attach a trailing zero
        // byte so we can print it out with printf.
        char *passwordBuffer = malloc(length + 1);
        strncpy (passwordBuffer, password, length);

        passwordBuffer[length] = '\0';
        printf ("Password = %s\n", passwordBuffer);
        free (passwordBuffer);
    }

    showList (list);
    SecKeychainItemFreeContent (&list, password);

} // dumpItem


static void showAccess (SecAccessRef accessRef) {
    CFArrayRef aclList;
    SecAccessCopyACLList(accessRef, &aclList);

    CFIndex count = CFArrayGetCount(aclList);
    printf ("%ld lists\n", count);

    for (int i = 0; i < count; i++) {
        SecACLRef acl = (SecACLRef) CFArrayGetValueAtIndex(aclList, i);
        
        CFArrayRef applicationList;
        CFStringRef description;
        CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR promptSelector;
        SecACLCopySimpleContents (acl, &applicationList, &description,
                                  &promptSelector);
        if (promptSelector.flags
            & CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE) {
            printf ("\t%d: ACL %s - Requires passphrase\n", i,
                    [(NSString *)description UTF8String]);
        } else {
            printf ("\t%d: ACL %s - Does not require passphrase\n", i,
                    [(NSString *)description UTF8String]);
        }
        CFRelease(description);

        if (applicationList == NULL) {
            printf ("\t\tNo application list %d\n", i);
            continue;
        }

        CFIndex appCount = CFArrayGetCount(applicationList);
        printf ("\t\t%ld applications in list %d\n", appCount, i);

        for (int j = 0; j < appCount; j++) {
            SecTrustedApplicationRef application;
            CFDataRef appData;
            application = (SecTrustedApplicationRef)
                CFArrayGetValueAtIndex(applicationList, j);
            SecTrustedApplicationCopyData(application, &appData);
            printf ("\t\t\t%s\n", CFDataGetBytePtr(appData));
            CFRelease(appData);
        }
        CFRelease(applicationList);
    }
} // showAccess


int main (int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
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
        dumpItem (item, true);

        // Get the SecAccess
        SecAccessRef access;
        SecKeychainItemCopyAccess (item, &access);
        showAccess (access);

        CFRelease (access);
        CFRelease (item);
        count++;
    }

    printf ("%d items found\n ", count);
    CFRelease (search);
    [pool drain];

    return EXIT_SUCCESS;
} // main

