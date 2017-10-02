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
static const CGFloat kCollectionViewLeftContentInset = 0.0;
static const CGFloat kCollectionViewBottomContentInset = 3.0;
static const CGFloat kCollectionViewRightContentInset = 0.0;

static const CGFloat kMinimumInteritemSpacing = 3.0;
static const CGFloat kMinimumLineSpacing = 3.0;

static const CGFloat perPage = 100;

@interface DCAsset : NSObject

@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *filenameWithoutExtension;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic) BOOL isRAW;

@end

@implementation DCAsset

- (void)setFilename:(NSString *)filename {
    _filename = filename;
    NSArray *fileComponents = [filename componentsSeparatedByString:@"."];
    NSString *fileExtension = [[fileComponents lastObject] lowercaseString];
    if ([fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"jpeg"]) {
        self.isRAW = NO;
    } else {
        self.isRAW = YES;
    }
    self.filenameWithoutExtension = [[fileComponents subarrayWithRange:NSMakeRange(0, fileComponents.count - 1)] componentsJoinedByString:@"."];
}

@end


@interface ImagePickerPhotosViewController () <UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

//@property (nonatomic, strong) PHFetchResult *assetFetchResults;
@property (nonatomic, strong) NSArray *assetFetchResults;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) NSInteger pageNumber;
@property (nonatomic) BOOL isLoading;
@property (nonatomic, strong) PHFetchOptions *fetchOptions;

@property (nonatomic) BOOL onlyShowPhotosWithDuplicateNames;
@property (strong, nonatomic) NSMutableArray *fileNames;
@end

@implementation ImagePickerPhotosViewController

- (void)dealloc
{
    self.collectionView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.fileNames = [@[] mutableCopy];
    self.pageNumber = 0;
    self.onlyShowPhotosWithDuplicateNames = YES;
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
            
            PHFetchResult *fetchResults = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:nil];
            
//            self.assetFetchResults = [fetchResults objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, fetchResults.count)]];

            NSMutableArray *photos = [@[] mutableCopy];
            for (PHAsset *asset in fetchResults) {
                NSArray *resources = [PHAssetResource assetResourcesForAsset:asset];
                NSString *orgFilename = ((PHAssetResource *)resources[0]).originalFilename;
                DCAsset *photo = [DCAsset new];
                photo.filename = orgFilename;
                photo.asset = asset;
                [photos addObject:photo];
            }
            
            self.assetFetchResults = photos;
            
            if (self.onlyShowPhotosWithDuplicateNames) {
                NSMutableArray *duplicatePhotos = [@[] mutableCopy];
                NSMutableDictionary *duplicates = [@{} mutableCopy];
                for (DCAsset *asset in self.assetFetchResults) {
                    NSMutableArray *content = duplicates[asset.filenameWithoutExtension];
                    if (content) {
                        [content addObject:asset];
                    } else {
                        content = [@[asset] mutableCopy];
                    }
                    duplicates[asset.filenameWithoutExtension] = content;
                }
                
                for (NSMutableArray *array in [duplicates allValues]) {
                    if (array.count > 1) {
                        [duplicatePhotos addObjectsFromArray:array];
                    }
                }
                self.assetFetchResults = duplicatePhotos;
            }
            
            self.assetFetchResults = [self.assetFetchResults sortedArrayUsingComparator:^NSComparisonResult(DCAsset *obj1, DCAsset *obj2) {
                return [obj1.filename compare:obj2.filename];
            }];

            dispatch_async(dispatch_get_main_queue(), ^(void) {
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
    DCAsset *asset = self.assetFetchResults[indexPath.item];
    return asset.asset;
}

#pragma mark - <UICollectionViewDataSource>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    [self loadAssets];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section;
{
	return self.assetFetchResults.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{    
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    
    ImagePickerPhotosCollectionViewCell *cell = (ImagePickerPhotosCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ImagePickerPhotosCollectionViewCell class]) forIndexPath:indexPath];
    
    DCAsset *photo = self.assetFetchResults[indexPath.item];
    cell.rawLabel.hidden = !photo.isRAW;
    
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
    return CGSizeMake(136, 136);
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
