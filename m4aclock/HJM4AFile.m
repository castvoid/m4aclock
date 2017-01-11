//
//  HJM4AFile.m
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>
#import "HJM4AFile.h"

@interface HJM4AFile () <HJM4AFileMetadataSource>

@property NSMutableDictionary *metaDict;
@property NSURL *url;
@property AVURLAsset *asset;

@end

@implementation HJM4AFile

- (id)initFromURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _url = url;
        _asset = [AVURLAsset URLAssetWithURL:self.url
                                         options:nil];
        _metaDict = setupMetadataDictionary(_asset);
        _data = [[HJM4AFileMetadata alloc] initWithMetadataSource:self];
    }
    
    return self;
}

NSMutableDictionary *setupMetadataDictionary(AVURLAsset *asset) {
    
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    NSArray<AVMetadataItem*> *metadata = asset.metadata;
    
    for (AVMetadataItem *item in metadata) {
        d[item.identifier] = item.value;
    }
    
    return d;
}

- (NSError*)saveChanges {
    return [self saveChangesToURL:self.url];
}

// Source: https://developer.apple.com/library/content/samplecode/avmetadataeditor/Introduction/Intro.html
- (NSArray*)generateMetadata {
    NSArray *sourceMetadata = self.asset.metadata;
    NSMutableArray *newMetadata = [NSMutableArray array];
    NSMutableDictionary *d = self.metaDict;
    
    //Find the identifiers that exist in the dictionary and the metadata and update them
    for (AVMetadataItem *item in sourceMetadata) {
        AVMutableMetadataItem *newItem = [item mutableCopy];
        
        NSString *identifier = [newItem identifier];
        if (d[identifier]) {
            newItem.value = d[identifier];
            [d removeObjectForKey:identifier];
        }
        
        if (newItem.value && ![newItem.value isEqual:[NSNull null]]) {
            [newMetadata addObject:newItem];
        }
    }
    
    // Insert ones in dict only
    for (NSString *identifier in [d keyEnumerator]) {
        id value = [d objectForKey:identifier];
        if (value && ![value isEqual:[NSNull null]]) {
            AVMutableMetadataItem *newItem = [AVMutableMetadataItem metadataItem];
            [newItem setIdentifier:identifier];
            [newItem setLocale:[NSLocale currentLocale]];
            [newItem setValue:value];
            [newItem setExtraAttributes:nil];
            [newMetadata addObject:newItem];
        }
    }
    
    return newMetadata;
}

- (NSError*)saveChangesToURL:(NSURL*)outFile {
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:self.asset
                                                                      presetName:AVAssetExportPresetPassthrough];
    [session setOutputFileType:AVFileTypeAppleM4A];
    [session setOutputURL:outFile];
    [session setMetadata:[self generateMetadata]];
    
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
