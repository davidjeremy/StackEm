//
//  NSData+Save.h
//  500px
//
//  Created by Jerome Scheer on 04/06/15.
//  Copyright (c) 2015 500px. All rights reserved.
//

@import Foundation;

@interface NSData (Save)

- (NSString *)saveInCacheDirectoryAtomically:(BOOL)atomically;

@end
