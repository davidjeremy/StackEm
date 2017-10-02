//
//  ImagePickerPhotosCollectionViewCell.h
//  500px
//
//  Created by Jerome Scheer on 21/04/15.
//  Copyright (c) 2015 500px. All rights reserved.
//

@import UIKit;
@import Photos;

@interface ImagePickerPhotosCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic, nonnull) IBOutlet UIImageView *photoImageView;
@property (strong, nonatomic, nonnull) IBOutlet UILabel *rawLabel;
@property (nonatomic) PHImageRequestID requestID;

@end
