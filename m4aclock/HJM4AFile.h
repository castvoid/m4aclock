//
//  HJM4AMetadata.h
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJM4AFileMetadata.h"
@interface HJM4AFile : NSObject

- (id)initFromURL:(NSURL*)url;
- (NSError*)saveChanges;
- (NSError*)saveChangesToURL:(NSURL*)outFile;

@property (readonly) HJM4AFileMetadata *data;

@end
