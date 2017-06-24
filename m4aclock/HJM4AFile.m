//
//  HJM4AFile.m
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

// This object acts as a source for the HJM4AFileMetadata, and has a
// HJM4AFileMetadata. The metadata for the file can be changed via its .metadata
// property

#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>
#import "HJM4AFile.h"

@interface HJM4AFile () <HJM4AFileMetadataSource>

// The m4a file's metadata. Updated when we update .metadata
@property NSMutableDictionary *metaDict;
@property NSURL *url; // URL of file this object references
@property AVURLAsset *asset;

@end

@implementation HJM4AFile

- (id)init __attribute__((unavailable("You must call initFromURL:"))) {
    self = nil;
    return self;
}

- (id)initFromURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _url = url;
        _asset = [AVURLAsset URLAssetWithURL:self.url
                                         options:nil];
        _metaDict = generateMetadataDictionary(_asset);
        _metadata = [[HJM4AFileMetadata alloc] initWithMetadataSource:self];
    }
    
    return self;
}

// Generates a new metadata dictionary from the m4a asset
NSMutableDictionary *generateMetadataDictionary(AVURLAsset *asset) {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    NSArray<AVMetadataItem*> *metadata = asset.metadata;
    
    for (AVMetadataItem *item in metadata) {
        d[item.identifier] = item.value;
    }
    
    return d;
}

// Generates an updated array of AVMetadataItems for the metadata of the asset.
// This method gets the existing array for the asset and updates it from our
// dictionary.
// Elsewhere we use a dicionary to map from identifier -> value for convenience,
// but in interacting with AVFoundation we must use this format.
// partially based on https://developer.apple.com/library/content/samplecode/avmetadataeditor/Introduction/Intro.html
- (NSArray*)generateMetadataArray {
    NSArray *sourceMetadata = self.asset.metadata;
    NSMutableArray *newMetadata = [NSMutableArray array];
    NSMutableDictionary *d = self.metaDict;
    NSMutableSet *includedIdentifiers = [NSMutableSet set];
    
    // Update items whose identifiers exist in both the dict and sourceMetadata
    for (AVMetadataItem *item in sourceMetadata) {
        AVMutableMetadataItem *newItem = [item mutableCopy];
        NSString *identifier = [newItem identifier];
        
        if (d[identifier]) {
            newItem.value = d[identifier];
        }
        
        if (newItem.value && ![newItem.value isEqual:[NSNull null]]) {
            [newMetadata addObject:newItem];
        }
        [includedIdentifiers addObject:identifier];
    }
    
    // Insert items that exist in the dict only with a new AVMutableMetadataItem
    for (NSString *identifier in [d keyEnumerator]) {
        if ([includedIdentifiers containsObject:identifier]) continue;
        
        id value = [d objectForKey:identifier];
        if (value && ![value isEqual:[NSNull null]]) {
            AVMutableMetadataItem *newItem = [AVMutableMetadataItem metadataItem];
            newItem.identifier = identifier;
            newItem.locale = NSLocale.currentLocale;
            newItem.value = value;
            newItem.extraAttributes = nil;
            [newMetadata addObject:newItem];
        }
    }
    
    return newMetadata;
}

- (NSError*)saveChanges {
    return [self saveChangesToURL:self.url];
}

- (NSError*)saveChangesToURL:(NSURL*)outFile {
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:self.asset
                                                                      presetName:AVAssetExportPresetPassthrough];
    [session setOutputFileType:AVFileTypeAppleM4A];
    [session setOutputURL:outFile];
    [session setMetadata:[self generateMetadataArray]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSError *error = nil;
    __block BOOL succeeded = NO;
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            succeeded = YES;
        } else {
            succeeded = NO;
            if (session.error) error = session.error;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return error;
}

- (NSObject*)getMetadataValueForKey:(NSString *)key {
    return [self.metaDict objectForKey:key];
}

- (void)setMetadataValue:(NSObject *)value forKey:(NSString *)key {
    [self.metaDict setObject:value forKey:key];
}

@end
