//
//  PXImagePickerPhotoViewController.m
//  500px
//
//  Created by Paddy O'Brien on 1/22/2014.
//  Copyright (c) 2014 500px. All rights reserved.
//

#import "ImagePickerPhotosViewController.h"
#import "ImagePickerPhotosCollectionViewCell.h"
#import "NSData+Save.h"

static const CGFloat kCollectionViewTopContentInset = 6.0;
static const CGFloat kCollectionViewLeftContentInset = 3.0;
static const CGFloat kCollectionViewBottomContentInset = 3.0;
static const CGFloat kCollectionViewRightContentInset = 3.0;

static const CGFloat kMinimumInteritemSpacing = 3.0;
static const CGFloat kMinimumLineSpacing = 3.0;

static const CGFloat perPage = 100;

@interface ImagePickerPhotosViewController () <UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) PHFetchResult *assetFetchResults;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) BOOL isLoading;
@property (nonatomic, strong) PHFetchOptions *fetchOptions;

@end

@implementation ImagePickerPhotosViewController

- (void)dealloc
{
    self.collectionView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.pageNumber = 0;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([ImagePickerPhotosCollectionViewCell class]) bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:NSStringFromClass([ImagePickerPhotosCollectionViewCell class])];
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.collectionViewLayout = [UICollectionViewFlowLayout new];
    
    // Do any additional setup after loading the view.
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.minimumInteritemSpacing = kMinimumInteritemSpacing;
    layout.minimumLineSpacing = kMinimumLineSpacing;
    layout.sectionInset = UIEdgeInsetsMake(kCollectionViewTopContentInset, kCollectionViewLeftContentInset, kCollectionViewBottomContentInset, kCollectionViewRightContentInset);

    self.titleLabel.text = self.assetCollection.localizedTitle;
    
    self.fetchOptions = [PHFetchOptions new];
    self.fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeImage];
//    self.fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    [self loadAssets];
}

- (void)loadAssets
{
    if (self.isLoading) {
        return;
    } else {
        self.isLoading = YES;
        self.pageNumber++;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^(void) {
            
            self.fetchOptions.fetchLimit = perPage * self.pageNumber;
            
//            PHFetchResult *fetchResults = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:self.fetchOptions];
            PHFetchResult *fetchResults = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                self.assetFetchResults = fetchResults;
                [self.collectionView reloadData];
                self.isLoading = NO;
            });
        });

    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)newSize withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:newSize withTransitionCoordinator:coordinator];
    if (!CGSizeEqualToSize(self.view.frame.size, newSize)) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

#pragma mark - Private methods

- (IBAction)backButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(userDidDismissPhotosPickerViewController:)]) {
        [self.delegate userDidDismissPhotosPickerViewController:self];
    }
}

- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath
{
    return self.assetFetchResults[indexPath.item];
}

#pragma mark - <UICollectionViewDataSource>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadAssets];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
	return self.assetFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{    
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    
    ImagePickerPhotosCollectionViewCell *cell = (ImagePickerPhotosCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ImagePickerPhotosCollectionViewCell class]) forIndexPath:indexPath];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = NO;
    
    CGFloat scale = MIN(2.0, [[UIScreen mainScreen] scale]);
    CGSize requestImageSize = CGSizeMake(CGRectGetWidth(cell.bounds) * scale, CGRectGetHeight(cell.bounds) * scale);
    PHImageRequestID requestID = [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:requestImageSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        cell.photoImageView.image = result;
    }];

    cell.requestID = requestID;
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImagePickerPhotosCollectionViewCell *updatedCell = (ImagePickerPhotosCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [[PHCachingImageManager defaultManager] cancelImageRequest:updatedCell.requestID];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(120, 120);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(kCollectionViewTopContentInset, kCollectionViewLeftContentInset, kCollectionViewBottomContentInset, kCollectionViewRightContentInset);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    PHImageRequestOptions *options = [PHImageRequestOptions new];
//    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
//    options.resizeMode = PHImageRequestOptionsResizeModeExact;
//    options.version = PHImageRequestOptionsVersionCurrent;
//    options.networkAccessAllowed = YES;
//    
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    
//    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
//        NSString *filePath = [imageData saveInCacheDirectoryAtomically:YES];
    
        if ([self.delegate respondsToSelector:@selector(imagePickerPhotosViewController:userDidSelectAsset:)]) {
            [self.delegate imagePickerPhotosViewController:self userDidSelectAsset:asset];
        }
//    }];
}

@end
