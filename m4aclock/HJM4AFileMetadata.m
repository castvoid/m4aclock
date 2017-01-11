//
//  HJM4AFileMetadata.m
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

#import "HJM4AFileMetadata.h"
#import <objc/runtime.h>

@interface HJM4AFileMetadata ()

@property id<HJM4AFileMetadataSource>dataSource;

@end

@implementation HJM4AFileMetadata

- (id)initWithMetadataSource:(id<HJM4AFileMetadataSource>)dataSource {
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            setupKeys();
            setupProperties([self class]);
        });
    }
    return self;
}

#pragma mark Properties

NSDictionary *keys;

void setupKeys() {
    keys = @{
             @"album":               @"itsk/%A9alb",
             @"albumSortOrder":      @"itsk/soal",
             @"albumArtist":         @"itsk/aART",
             @"albumArtistSortOrder":@"itsk/soaa",
             @"artist":              @"itsk/%A9ART",
             @"artistSortOrder":     @"itsk/soar",
             @"bpm":                 @"itsk/tmpo",
             @"comment":             @"itsk/%A9cmt",
             @"composer":            @"itsk/%A9wrt",
             @"composerSortOrder":   @"itsk/soco",
             @"copyright":           @"itsk/cprt",
             @"cover":               @"itsk/covr",
             @"diskNumber":          @"itsk/disk",
             @"mediaDescription":    @"itsk/desc",
             @"encodedBy":           @"itsk/%A9too",
             @"genre":               @"itsk/%A9gen",
             @"grouping":            @"itsk/%A9grp",
             @"lyrics":              @"itsk/%A9lyr",
             @"partOfCompilation":   @"itsk/cpil",
             @"partOfGaplessAlbum":  @"itsk/pgap",
             @"podcast":             @"itsk/pcst",
             @"podcastCategory":     @"itsk/catg",
             @"podcastEpisodeGuid":  @"itsk/egid",
             @"podcastKeywords":     @"itsk/keyw",
             @"podcastURL":          @"itsk/purl",
             @"purchaseDate":        @"itsk/purd",
             @"rating":              @"itsk/rtng",
             @"showName":            @"itsk/tvsh",
             @"showSortOrder":       @"itsk/sosn",
             @"trackNumber":         @"itsk/trkn",
             @"name":                @"itsk/%A9nam",
             @"sortOrder":           @"itsk/sonm",
             @"year":                @"itsk/%A9day",
             @"purchasedBy":         @"itsk/ownr",
             @"AppleID":             @"itsk/apID",
             @"iTunesWWW":           @"itlk/com.apple.iTunes.WWW",
             };
}

void setupProperties(Class class) {
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(class, &count);
    
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        
        if ([keys objectForKey:name] == nil) continue;
        
        NSString *setterName = [NSString stringWithFormat:@"set%@%@:",
                                [[name substringToIndex:1] uppercaseString],
                                [name substringFromIndex:1]];
        
        Method getter = class_getInstanceMethod(class, NSSelectorFromString(name));
        Method setter = class_getInstanceMethod(class, NSSelectorFromString(setterName));
        
        method_setImplementation(getter, (IMP)swizzleGetter);
        method_setImplementation(setter, (IMP)swizzleSetter);
    }
}

Class getClassForPropertyName(HJM4AFileMetadata* self, NSString *name) {
    objc_property_t property = class_getProperty(self.class, name.UTF8String);
    const char *propertyAttrs = property_getAttributes(property);
    
    // attrs = 'T<type>,...'
    // where type = '@"<ClassName>"' or something else.
    if (propertyAttrs[1] != '@' || propertyAttrs[2] != '"') return nil;
    const char *start = &propertyAttrs[3];
    const char *end = strchr(start, ',');
    if (end == NULL) return nil;
    ptrdiff_t length = end-start-1;
    
    NSData *data = [NSData dataWithBytes:start length:length];
    NSString *string = [[NSString alloc] initWithData:data
                                             encoding:NSUTF8StringEncoding];
    
    return NSClassFromString(string);
}

NSObject *swizzleGetter(HJM4AFileMetadata* self, SEL _cmd) {
    NSString *keyname = NSStringFromSelector(_cmd);
    NSString *key = keys[keyname];
    
    Class c = getClassForPropertyName(self, keyname);
    if (c == nil || ![c isSubclassOfClass:NSObject.class]) return nil;
    
    NSObject *ret = [self.dataSource getMetadataValueForKey:key];
    
    // Special date handling
    if ([c isSubclassOfClass:NSDate.class]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [df dateFromString:(NSString*)ret];
        ret = date;
    }
    
    return ret;
}

void swizzleSetter(HJM4AFileMetadata* self, SEL _cmd, NSObject *value) {
    NSString *selector = NSStringFromSelector(_cmd);
    // note: first char of this is capitalised. most (but not all) are lowercase!
    
    NSString *name = [selector substringWithRange:NSMakeRange(3, selector.length - 4)];
    NSString *key = keys[name];
    if (key == nil) {
        NSRange range = NSMakeRange(0, 1);
        NSString *firstChar = [[name substringWithRange:range] lowercaseString];
        name = [name stringByReplacingCharactersInRange:range withString:firstChar];
        key = keys[name];
    }
    
    NSObject *toStore = value;
    
    // Special date handling
    if ([value.class isSubclassOfClass:NSDate.class]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *string = [df stringFromDate:(NSDate*)value];
        toStore = string;
    }
    
    if (toStore == nil) toStore = [NSNull null];
    
    [self.dataSource setMetadataValue:toStore forKey:key];
}

//- (NSDate*)purchaseDate {
//    NSString *str = [self getPropertyStringByKey:DICT_KEY_PURCHASEDATE];
//    if (str == nil) return nil;
//
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSDate *date = [df dateFromString:str];
//    return date;
//}
//
//- (void)setPurchaseDate:(NSDate *)purchaseDate {
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString *str = [df stringFromDate:purchaseDate];
//    [self setProperty:str byKey:DICT_KEY_PURCHASEDATE];
//}

@end
