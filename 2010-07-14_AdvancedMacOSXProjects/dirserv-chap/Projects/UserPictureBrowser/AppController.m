#import "AppController.h"
#import "User.h"
#include <stdlib.h>
#include <stdio.h>
#include <DirectoryService/DirServices.h>
#include <DirectoryService/DirServicesUtils.h>
#include <DirectoryService/DirServicesConst.h>

@implementation AppController

- (void)fillUsersWithData
{
    long dirStatus;
    tDirReference gDirRef;
    tDirNodeReference nodeRef;
    tDataListPtr nodeName;
    tDataList recNames;
    tDataList recTypes;
    tDataList attrTypes;
    tRecordEntry *pRecEntry;
    unsigned long recCount, i, j;
    tAttributeListRef attrListRef;
    tAttributeValueListRef valueRef;
    tAttributeValueEntry *pValueEntry;
    tAttributeEntry *pAttrEntry;
    tDataBufferPtr dataBuffer;
    unsigned long bufferCount;
    tContextData context = NULL;
    char * pPath;
    
    // Start a directory service session
    dsOpenDirService( &gDirRef );
    dataBuffer = dsDataBufferAllocate( gDirRef, 32 * 1024 );

    // Find the node for looking up users, pack the list in dataBuffer
    dirStatus = dsFindDirNodes(gDirRef, dataBuffer, NULL, eDSAuthenticationSearchNodeName, &bufferCount, &context );
    
    if (dirStatus != eDSNoErr) {
        NSLog(@"Finding Authentication Node Failed: %d", dirStatus);
        return;
    } else {
        NSLog(@"Found %d nodes for authentication", bufferCount);
    }
    
    // Get the name of the first node in dataBuffer
    nodeName = dsDataListAllocate( gDirRef );
    dirStatus = dsGetDirNodeName( gDirRef, dataBuffer, 1, &nodeName );
    if (dirStatus != eDSNoErr) {
        NSLog(@"Getting Node Name Failed: %d", dirStatus);
        return;
    }
    
    // Display node name as path
    pPath = dsGetPathFromList( gDirRef, nodeName, "/" );
    NSLog(@"Node = %s", pPath );
    free(pPath);
    
    // Open the node and store in nodeRef
    dirStatus = dsOpenDirNode( gDirRef, nodeName, &nodeRef);
    if (dirStatus != eDSNoErr) {
        NSLog(@"Opening Node Failed: %d", dirStatus);
        return;
    }

    // Describe what you are looking for as three lists of strings
    dsBuildListFromStringsAlloc ( gDirRef, &recNames, kDSRecordsAll, NULL );
    dsBuildListFromStringsAlloc ( gDirRef, &recTypes, kDSStdRecordTypeUsers, NULL );
    dsBuildListFromStringsAlloc ( gDirRef, &attrTypes, "dsAttrTypeStandard:RecordName", "dsAttrTypeStandard:RealName", "dsAttrTypeStandard:Picture", NULL );
    do 
    {
        // Get the list of all the records
        // Call this until context is null.
        dsGetRecordList( nodeRef, dataBuffer, &recNames, eDSExact,
                        &recTypes, &attrTypes, 0, &recCount, &context );
        printf("Get record list returned %lu record entries\n", recCount);
        for ( i = 1; i <= recCount; i++ )
        {
            // Get a record from the list
            dsGetRecordEntry( nodeRef, dataBuffer, i, &attrListRef, &pRecEntry );
            
            // If it doesn't have all three attributes,  we aren't interested
            if (pRecEntry->fRecordAttributeCount == 3) 
            {
                NSString *userName = nil;
                NSString *realName = nil;
                NSString *picturePath = nil;
                for ( j = 1; j <= 3; j++ )
                {
                    NSString *key;
                    NSString *value;
                    
                    // Read the attribute
                    dsGetAttributeEntry( nodeRef, dataBuffer, attrListRef, j,
                                &valueRef, &pAttrEntry );
                    key = [NSString stringWithUTF8String:pAttrEntry->fAttributeSignature.fBufferData];
                    
                    // Read the first value for the attribute
                    dsGetAttributeValue( nodeRef, dataBuffer, 1, valueRef,
                                    &pValueEntry
);
                    value = [NSString stringWithUTF8String:pValueEntry->fAttributeValueData.fBufferData];
                    
                    // Tidy up attribute-level data
                    dsDeallocAttributeValueEntry( gDirRef, pValueEntry );
                    pValueEntry = NULL;
                    dsDeallocAttributeEntry(gDirRef, pAttrEntry);
                    pAttrEntry = NULL;
                    dsCloseAttributeValueList( valueRef );

                    // Put the data in the right variable
                    if ([key isEqual:@"dsAttrTypeStandard:Picture"]) {
                        picturePath = value;
                    }
                    if ([key isEqual:@"dsAttrTypeStandard:RealName"]) {
                        realName = value;
                    }
                    if ([key isEqual:@"dsAttrTypeStandard:RecordName"]) {
                        userName = value;
                    }

                }
                // Create a user object
                User *newUser = [[User alloc] initWithUserName:userName
                                                realName:realName
                                                picturePath:picturePath];
                [users addObject:newUser];
                [newUser release];
                
            }   
            // Tidy up record-level data
            dsCloseAttributeList( attrListRef );
            attrListRef = NULL;
            dsDeallocRecordEntry( gDirRef, pRecEntry );
            pRecEntry = NULL;
        }
    } while (context != NULL); // Loop until all of the data has been obtained.
    
    // Tidy up node-level data
    dsDataListDeallocate(gDirRef, &recNames);
    dsDataListDeallocate(gDirRef, &recTypes);
    dsDataListDeallocate(gDirRef, &attrTypes);
    dsDataListDeallocate(gDirRef,nodeName);
    dsCloseDirNode( nodeRef );
    
    // Tidy up session-level data
    dsCloseDirService( gDirRef );
}

- (id)init
{
    [super init];
    users = [[NSMutableArray alloc] init];
    [self fillUsersWithData];
    return self;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    int newSelection = [tableView selectedRow];
    if (newSelection >= 0) {
        NSImage *i = [[users objectAtIndex:newSelection] picture];
        [imageView setImage:i];
    }
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [users count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    User *u = [users objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    return [u valueForKey:identifier];
}

@end
