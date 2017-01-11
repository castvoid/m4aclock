//
//  HJM4AFileMetadata.h
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HJM4AFileMetadataSource
- (NSObject*)getMetadataValueForKey:(NSString*)key;
- (void)setMetadataValue:(NSObject*)value forKey:(NSString*)key;
@end


@interface HJM4AFileMetadata : NSObject

- (id)initWithMetadataSource:(id<HJM4AFileMetadataSource>)dataSource;

@property NSString *album;
@property NSString *albumSortOrder;
@property NSString *albumArtist;
@property NSString *albumArtistSortOrder;
@property NSString *artist;
@property NSString *artistSortOrder;
@property NSString *bpm;
@property NSString *comment;
@property NSString *composer;
@property NSString *composerSortOrder;
@property NSString *copyright;
@property NSData *cover;
@property NSData *diskNumber;
@property NSString *mediaDescription;
@property NSString *encodedBy;
@property NSString *genre;
@property NSString *grouping;
@property NSString *lyrics;
@property NSNumber *partOfCompilation;
@property NSNumber *partOfGaplessAlbum;
@property NSString *podcast;
@property NSString *podcastCategory;
@property NSString *podcastEpisodeGuid;
@property NSString *podcastKeywords;
@property NSString *podcastURL;
@property NSDate *purchaseDate;
@property NSNumber *rating;
@property NSString *showName;
@property NSString *showSortOrder;
@property NSData *trackNumber;
@property NSString *name;
@property NSString *sortOrder;
@property NSDate *year;
@property NSString *purchasedBy;
@property NSString *AppleID;
@property NSString *iTunesWWW;

@end
