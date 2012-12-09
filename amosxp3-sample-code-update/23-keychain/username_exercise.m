// username_exercise.m - Save username and password to keychain.

// clang -g -Weverything -Wno-deprecated-declarations -framework Security -framework Foundation username_exercise.m -o username_exercise

#import <Security/Security.h>
#import <Foundation/Foundation.h>

char kServiceName[] = "com.bignerdranch.username_exercise";

int main (void) {
    SecKeychainRef keychain = NULL;
    OSStatus err = SecKeychainCopyDefault(&keychain);
    require_noerr_action(err, CantCopyDefault,
        fprintf(stderr, "%s: *** Can't copy default keychain.\n",
                getprogname()));

    char *account_name = "username";
    const size_t account_len = strlen(account_name);

    // Delete the item if it is present so that add succeeds.
    // In reality, you would find then modify the item,
    // and only add if it weren't already present.
    SecKeychainAttribute attribs[] = {
        /* TAG                LENGTH                 DATA */
        {kSecServiceItemAttr, sizeof(kServiceName), kServiceName},
        {kSecAccountItemAttr, (UInt32)account_len,  account_name},
    };
    SecKeychainAttributeList attrList[1];
    attrList[0].count = sizeof(attribs)/sizeof(*attribs);
    attrList[0].attr = attribs;

    SecKeychainSearchRef search = NULL;
    err = SecKeychainSearchCreateFromAttributes(
            keychain,
            kSecGenericPasswordItemClass,
            attrList,
            &search);
    require_noerr_action(err, CantCreateSearch,
        fprintf(stderr, "%s: *** Failed to create search for item.\n",
                getprogname()));

    SecKeychainItemRef item = NULL;
    while (errSecItemNotFound != SecKeychainSearchCopyNext(search, &item)) {
        err = SecKeychainItemDelete(item);
        check_noerr_string(err, "*** Failed to delete item.");
        CFRelease(item);
    }

    const char *password = "password";
    err = SecKeychainAddGenericPassword(
            keychain,
            sizeof(kServiceName), kServiceName,
            (UInt32)account_len, account_name,
            (UInt32)strlen(password), password,
            &item);
    require_noerr_action(err, CantAddItem,
        fprintf(stderr, "%s: *** Failed adding item: %s/%s.\n",
                getprogname(), kServiceName, account_name));

    printf("%s: Added item: %s/%s.\n", getprogname(),
           kServiceName, account_name);
    CFShow(item);
    CFRelease(item), item = NULL;

CantCreateSearch:
CantAddItem:
    CFRelease(keychain), keychain = NULL;

CantCopyDefault:
    if (noErr != err) {
        CFStringRef msg = SecCopyErrorMessageString(err, NULL/*reserved*/);
        if (msg) {
            CFShow(msg);
            CFRelease(msg), msg = NULL;
        }
    }
    return err;
}

