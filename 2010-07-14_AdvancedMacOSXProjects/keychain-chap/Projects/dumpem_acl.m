// dumpem.m -- screw around with keychain stuff

/*
compile with
cc -g -Wall -framework Security -framework Foundation -framework CoreFoundation -o dumpem_acl dumpem_acl.m
 */
#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>


#import <stdlib.h>	// for EXIT_SUCCESS
#import <stdio.h>	// for printf() and friends
#import <string.h>	// for strncpy

// given a carbon-style 4-byte character identifier,
// make a C string that can be given to printf

const char *fourByteCodeString (UInt32 code)
{
    // sick-o hack to quickly assign an identifier
    // into a character buffer
    typedef union theCheat {
	UInt32 theCode;
	char theString[4];
    } theCheat;

    static char string[5];

    ((theCheat*)string)->theCode = code;
    string[4] = '\0';

    return (string);

} // fourByteCodeString



void showList (SecKeychainAttributeList list)
{
    char buffer[1024];
    SecKeychainAttribute attr;

    int i;

    for (i = 0; i < list.count; i++) {

	attr = list.attr[i];

	if (attr.length < 1024) {
	    // make a copy of the data so we can stick on
	    // a trailing zero byte
	    strncpy (buffer, attr.data, attr.length);
	    buffer[attr.length] = '\0';

	    printf ("\t%d: '%s' = \"%s\"\n", 
		    i, fourByteCodeString(attr.tag), buffer);
	} else {
	    printf ("attribute %d is more than 1K\n", i);
	}
    }

} // showList

void showAccess (SecAccessRef accessRef)
{
  int count, i;
  CFArrayRef aclList, applicationList;
  SecACLRef acl;
  CFStringRef description;
  CSSM_ACL_KEYCHAIN_PROMPT_SELECTOR promptSelector;
  SecTrustedApplicationRef application;
  CFDataRef appData;

  SecAccessCopyACLList(accessRef, &aclList);
  count = CFArrayGetCount(aclList);
  printf("%d lists\n", count);
  for (i = 0; i < count; i++) {
    acl = (SecACLRef)CFArrayGetValueAtIndex(aclList, i);
    SecACLCopySimpleContents(acl, &applicationList, &description, &promptSelector);
    if (promptSelector.flags & CSSM_ACL_KEYCHAIN_PROMPT_REQUIRE_PASSPHRASE) {
        NSLog(@"%d: ACL %@ - Requires passphrase\n", i, description);
    } else {
        NSLog(@"%d: ACL %@ - Does not require passphrase\n",i, description);
    }
    //CFRelease(description);
    if (applicationList == NULL) {
      printf("No application list %d\n", i);
      continue;
    }
    int j, appCount;
    appCount = CFArrayGetCount(applicationList);
    printf("%d applications in list %d\n", appCount, i);
    for (j = 0; j < appCount; j++) {
      application = (SecTrustedApplicationRef)CFArrayGetValueAtIndex(applicationList, j);
      SecTrustedApplicationCopyData(application, &appData);
      printf("\t%s\n",CFDataGetBytePtr(appData));
      //CFRelease(appData);
    }
    //CFRelease(applicationList);
  }
}

void dumpItem (SecKeychainItemRef item)
{
    UInt32 length;
    char *password = NULL;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;

    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecModDateItemAttr;
    attributes[3].tag = kSecSecurityDomainItemAttr;
    attributes[4].tag = kSecServerItemAttr;
    attributes[5].tag = kSecAuthenticationTypeItemAttr;
    attributes[6].tag = kSecPortItemAttr;
    attributes[7].tag = kSecPathItemAttr;

    list.count = 8;
    list.attr = attributes;

    SecKeychainItemCopyContent (item, NULL, &list, &length, 
				(void **)&password);

    

    // use this version if you don't really want the password,
    // but just want to peek at the attributes

    // SecKeychainItemCopyContent (item, NULL, &list, NULL, NULL);

    if (password != NULL) {

	// copy the password into a buffer so we can attach a
	// trailing zero byte in order to be able to print
	// it out with printf
	char passwordBuffer[1024];

	if (length > 1023) {
	    length = 1023; // save room for trailing \0
	}
	strncpy (passwordBuffer, password, length);

	passwordBuffer[length] = '\0';
	printf ("Password = %s\n", passwordBuffer);

	showList (list);
	
	SecKeychainItemFreeContent (&list, password);

    }

} // dumpItem



int main (int argc, char *argv[])
{
    SecKeychainSearchRef search;
    SecKeychainItemRef item;
    SecKeychainAttributeList list;
    SecKeychainAttribute attribute;
    int i = 0;

    // create an attribute list with just one attribute specified
    attribute.tag = kSecAccountItemAttr;
    attribute.length = 5;
    attribute.data = "yourUsernameHere";

    list.count = 1;
    list.attr = &attribute;

    SecKeychainSearchCreateFromAttributes (NULL,
					   kSecInternetPasswordItemClass,
					   &list,
					   &search);
    
    while (SecKeychainSearchCopyNext (search, &item)
	   == 0) {
        SecAccessRef access;
	dumpItem (item);
        
        SecKeychainItemCopyAccess(item, &access);
	showAccess(access);
	//CFRelease(access);
        //CFRelease (item);

	i++;
    }

    printf ("%d items found\n", i);
    CFRelease (search);

    return (EXIT_SUCCESS);

} // main

