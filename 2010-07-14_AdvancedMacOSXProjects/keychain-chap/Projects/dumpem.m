// dumpem.m -- look into the keychain

/*
compile with
cc -g -Wall -framework Security -framework CoreFoundation \
   -o dumpem dumpem.m
*/

#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>

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



void dumpItem (SecKeychainItemRef item)
{
    UInt32 length;
    char *password = NULL;
    SecKeychainAttribute attributes[8];
    SecKeychainAttributeList list;
    OSErr result;

    attributes[0].tag = kSecAccountItemAttr;
    attributes[1].tag = kSecDescriptionItemAttr;
    attributes[2].tag = kSecModDateItemAttr;
    attributes[3].tag = kSecServiceItemAttr;
    attributes[4].tag = kSecGenericItemAttr;

    list.count = 5;
    list.attr = attributes;

    result = SecKeychainItemCopyContent (item, NULL, &list, &length, 
					 (void **)&password);
    // use this version if you don't really want the password,
    // but just want to peek at the attributes

    // result = SecKeychainItemCopyContent (item, NULL, &list, NULL, NULL);

    if (result != noErr) {
	printf ("dumpItem: result of %d\n", result);
	return;
    }

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
    OSErr result;
    int count = 0;

    // create an attribute list with just one attribute specified
    attribute.tag = kSecAccountItemAttr;
    attribute.length = 12;
    attribute.data = "bignerdranch";

    list.count = 1;
    list.attr = &attribute;

    result = SecKeychainSearchCreateFromAttributes 
	(NULL,
	 kSecInternetPasswordItemClass,
	 &list,
	 &search);

    if (result != noErr) {
	printf ("result %d from "
		"SecKeychainSearchCreateFromAttributes\n",
		result);
    }

    while (SecKeychainSearchCopyNext (search, &item)
	   != errSecItemNotFound) {
	dumpItem (item);
	CFRelease (item);
	count++;
    }

    printf ("%d items found\n", count);
    CFRelease (search);

    return (EXIT_SUCCESS);

} // main

