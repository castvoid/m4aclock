//
//  main.m
//  m4aclock
//
//  Created by Harry Jones on 11/01/2017.
//  Copyright © 2017 Harry Jones. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "HJM4AFile.h"

void checkArgs(int argc, const char *argv[]) {
    int returnCode = 0;
    
    if (argc < 2) {
        returnCode = 1;
        goto fail;
    }
    
    if (strcmp("--help",argv[1]) == 0) {
        goto fail;
    }
    
    if (strcmp("-c",argv[1]) == 0 && argc < 3) {
        returnCode = 1;
        goto fail;
    }
    
    return;
    
fail:
    printf("m4aclock 0.1 - Update M4A purchase time to now\n");
    printf("USAGE: [-c] <input list>\n");
    printf("OPTIONS:\n");
    printf("  -c\t\tRemove purchaser information\n");
    exit(returnCode);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        checkArgs(argc, argv);
        
        int start = 1;
        bool clean_purchaser = false;
        
        if (strcmp("-c",argv[1]) == 0) {
            start = 2;
            clean_purchaser = true;
        }
        
        int count = argc - start;
        
        for (int i = start; i < argc; i++) {
            NSString *path = [[NSString stringWithUTF8String:argv[i]] stringByExpandingTildeInPath];
            NSURL *url = [NSURL fileURLWithPath:path];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:path]) {
                fprintf(stderr, "No file found at %s. Exiting...\n", path.UTF8String);
                exit(1);
            }
            HJM4AFile *file = [[HJM4AFile alloc] initFromURL:url];
            
            printf("Updating %d/%d – '%s'...", 1+i-start, count, file.metadata.name.UTF8String);
            
            file.metadata.purchaseDate = [NSDate date];
            if (clean_purchaser) {
                file.metadata.iTunesWWW = nil;
                file.metadata.AppleID = nil;
                file.metadata.copyright = nil;
                file.metadata.comment = nil;
            }
            
            NSError *err;
            if (!err) [fileManager removeItemAtPath:path error:&err];
            if (!err) err = [file saveChangesToURL:url];
            
            if (!err) {
                printf(" OK\n");
            } else {
                printf(" Failed!\n");
                fprintf(stderr, "Couldn't save to %s.\n", url.relativePath.UTF8String);
                fprintf(stderr, "Got error: %s\n", err.description.UTF8String);
                fprintf(stderr, "Exiting...\n");
                exit(1);
            }
        }
        printf("Done.\n");
    }
    return 0;
}
