//
//  PXImagePickerSetsViewController.h
//  500px
//
//  Created by Paddy O'Brien on 1/22/2014.
//  Copyright (c) 2014 500px. All rights reserved.
//


@import UIKit;
@import Photos;

@class ImagePickerSetsViewController;

@protocol ImagePickerSetsViewControllerDelegate <NSObject>

@optional
- (void)imagePickerSetsViewController:(ImagePickerSetsViewController *)imagePickerSetsViewController
               userDidSelectAllPhotos:(PHFetchResult *)allPhotosFetchResult;
@required
- (void)imagePickerSetsViewController:(ImagePickerSetsViewController *)imagePickerSetsViewController
         userDidSelectAssetCollection:(PHAssetCollection *)group;
- (void)imagePickerSetsViewController:(ImagePickerSetsViewController *)imagePickerSetsViewController
                   userDidSelectAsset:(PHAsset *)asset;
- (void)userDidDismissImagePickerSetsViewController:(ImagePickerSetsViewController *)imagePickerSetsViewController;

@end

@interface ImagePickerSetsViewController : UIViewController

@property (nonatomic, weak) id <ImagePickerSetsViewControllerDelegate> delegate;

@end
