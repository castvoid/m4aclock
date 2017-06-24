//
//  HJM4AMetadata.h
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

// A HJM4AFile allows for accessing data about a specific M4A file on disk.

#import <Foundation/Foundation.h>
#import "HJM4AFileMetadata.h"
@interface HJM4AFile : NSObject

- (id)initFromURL:(NSURL*)url;
- (NSError*)saveChanges;
- (NSError*)saveChangesToURL:(NSURL*)outFile;

// The HJM4AFileMetadata doesn't store its own copy of the metadata, it
// interacts with this object to do set/get metadata as needed
@property (readonly) HJM4AFileMetadata *metadata;

@end
