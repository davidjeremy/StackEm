//
//  PXImagePickerPhotoViewController.h
//  500px
//
//  Created by Paddy O'Brien on 1/22/2014.
//  Copyright (c) 2014 500px. All rights reserved.
//


@import UIKit;
@import Photos;
@import Foundation;

@protocol PickerPhotosDelegate <NSObject>

- (void)userDidDismissPhotosPickerViewController:(UIViewController *)viewController;
- (void)imagePickerPhotosViewController:(UIViewController *)viewController userDidSelectAsset:(PHAsset *)asset;

@end



@class ImagePickerPhotosViewController;

@interface ImagePickerPhotosViewController : UIViewController

@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, weak) id <PickerPhotosDelegate> delegate;

@end
