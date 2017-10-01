//
//  ImagePickerPhotosCollectionViewCell.m
//  500px
//
//  Created by Jerome Scheer on 21/04/15.
//  Copyright (c) 2015 500px. All rights reserved.
//

#import "ImagePickerPhotosCollectionViewCell.h"

@implementation ImagePickerPhotosCollectionViewCell

- (void)prepareForReuse
{
    self.photoImageView.image = nil;
    [[PHCachingImageManager defaultManager] cancelImageRequest:self.requestID];
}

@end
