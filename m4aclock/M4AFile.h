//
//  M4AMetadata.h
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

// A M4AFile allows for accessing data about a specific M4A file on disk.

#import <Foundation/Foundation.h>
#import "M4AFileMetadata.h"
@interface M4AFile : NSObject

- (id)init __attribute__((unavailable("You must call initFromURL:error:")));
- (id)initFromURL:(NSURL*)url error:(NSError**)errorPtr;
- (NSError*)saveChanges;
- (NSError*)saveChangesToURL:(NSURL*)outFile;

// The M4AFileMetadata doesn't store its own copy of the metadata, it
// interacts with this object to do set/get metadata as needed
@property (readonly) M4AFileMetadata *metadata;

@end
