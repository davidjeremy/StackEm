//
//  NSData+Save.m
//  500px
//
//  Created by Jerome Scheer on 04/06/15.
//  Copyright (c) 2015 500px. All rights reserved.
//

#import "NSData+Save.h"

@implementation NSData (Save)

- (NSString *)saveInCacheDirectoryAtomically:(BOOL)atomically
{
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"photos"];
    [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];

    filePath = [filePath stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    BOOL result = [self writeToFile:filePath atomically:atomically];
    
    if (result) {
        return filePath;
    } else {
        return nil;
    }
}

@end
