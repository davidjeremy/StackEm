//
//  PXImagePickerSetsViewController.m
//  500px
//
//  Created by Paddy O'Brien on 1/22/2014.
//  Copyright (c) 2014 500px. All rights reserved.
//

#import "ImagePickerSetsViewController.h"
#import "ImagePickerPhotosViewController.h"
#import "NSData+Save.h"
#import "ImagePickerSetsTableViewCell.h"

#define kCellBorderDefaultPadding UIEdgeInsetsMake(0, -0.5, -0.5, 0)

static const CGFloat kHeaderTitlePhoneLeftPadding = 10.0;
static const NSInteger kRecentPhotosCount = 20;

@interface ImagePickerSetsViewController () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, PickerPhotosDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;

@property (nonatomic, strong) NSMutableArray *albums;
@property (nonatomic, strong) NSMutableArray *smartAlbums;

@property (nonatomic, strong) NSMutableArray *recentAssets;
@property (nonatomic, strong) PHFetchResult *allPhotosFetchResult;

@end

@implementation ImagePickerSetsViewController

- (void)dealloc
{
    self.tableView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.titleLabel.text = NSLocalizedString(@"upload_photo", @"Title of List of albums view");
    self.navigationController.navigationBarHidden = YES;
    
    if ([self.navigationController.viewControllers.firstObject isEqual:self]) {
        [self.leftButton setImage:[UIImage imageNamed:@"close-button"] forState:UIControlStateNormal];
    }
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ImagePickerSetsTableViewCell class]) bundle:[NSBundle mainBundle]] forCellReuseIdentifier:NSStringFromClass([ImagePickerSetsTableViewCell class])];
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [self reloadPhotoGroups];
    } else if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusNotDetermined) {
        UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"denied_access_of_your_photos", @"Image Set Picker authorization alert title") message:NSLocalizedString(@"enable_access_in_privacy_settings", @"Image Set Picker authorization alert message") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"not_now", @"Image picker authorization alert") style:UIAlertActionStyleCancel handler:nil]];
        
        [alertViewController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action_settings", @"Go to settings capture authorization alert") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
        
        [self presentViewController:alertViewController animated:YES completion:nil];
    } else {
        // authorizationStatus == PHAuthorizationStatusNotDetermined
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == PHAuthorizationStatusAuthorized) {
                    [self reloadPhotoGroups];
                } else {
                    [self.smartAlbums removeAllObjects];
                    [self.albums removeAllObjects];
                    [self.tableView reloadData];
                }
            });
        }];
    }
}

- (void)closeButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(userDidDismissImagePickerSetsViewController:)]) {
        [self.delegate userDidDismissImagePickerSetsViewController:self];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // When we display the set picker (coming from the camera UI), for some reason, the view controller doesn't rotate
    // This method seems to fix the problem
    [UIViewController attemptRotationToDeviceOrientation];
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.tableView reloadData];
}

#pragma mark - Private methods

- (IBAction)backButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(userDidDismissImagePickerSetsViewController:)]) {
        [self.delegate userDidDismissImagePickerSetsViewController:self];
    }
}

- (void)reloadPhotoGroups
{
    [self.smartAlbums removeAllObjects];
    [self.albums removeAllObjects];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^(void) {
        // Smart Albums
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
            
            if (collection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumScreenshots
                && collection.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden) {
                
                PHFetchOptions *options = [PHFetchOptions new];
                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
                
                PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:options];
                
                if (assetsFetchResult.count > 0) {
                    if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                        [self.smartAlbums insertObject:collection atIndex:0];
                    } else {
                        [self.smartAlbums addObject:collection];
                    }
                }
            }
        }];
        
        // Albums
        PHFetchOptions *options = [PHFetchOptions new];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"localizedTitle" ascending:YES]];
        options.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
        
        PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:options];
        
        [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
            [self.albums addObject:collection];
        }];
        
        // Recent photos
        PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
        allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
        allPhotosOptions.fetchLimit = kRecentPhotosCount;
        
        self.allPhotosFetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosOptions];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.tableView reloadData];
        });
    });
}

- (NSString *)cellSubtitleForCount:(NSInteger)photoCount
{
    NSString *cellSubtitle = [NSString stringWithFormat:@"%@ %@", @(photoCount), NSLocalizedString(@"photos", nil)];
    if(photoCount == 1) {
        cellSubtitle = [NSString stringWithFormat:@"%@ %@", @(photoCount), NSLocalizedString(@"photo", nil)];
    }
    
    return cellSubtitle;
}

- (void)loadAsset:(PHAsset *)asset forCell:(ImagePickerSetsTableViewCell *)cell
{
    [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(cell.posterImageView.bounds.size.width * 2, cell.posterImageView.bounds.size.height * 2) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        cell.posterImageView.image = result;
    }];
}

#pragma mark - <TableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.smartAlbums.count;
    }

    if (section == 1) {
        return self.albums.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ImagePickerSetsTableViewCell *cell = (ImagePickerSetsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([ImagePickerSetsTableViewCell class]) forIndexPath:indexPath];
    
    PHAssetCollection *assetCollection;
    
    if (indexPath.section == 0) {
        assetCollection = (PHAssetCollection *)[self.smartAlbums objectAtIndex:indexPath.row];
    } else {
        assetCollection = (PHAssetCollection *)[self.albums objectAtIndex:indexPath.row];
    }
    
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
    cell.title.text = assetCollection.localizedTitle;
    cell.subTitle.text = [self cellSubtitleForCount:assetsFetchResult.count];
    
    [self loadAsset:assetsFetchResult.firstObject forCell:cell];
    
    cell.hideDisclosureIndicator = NO;
    return cell;
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PHAssetCollection *assetCollection;
    
    if (indexPath.section == 0) {
        assetCollection = [self.smartAlbums objectAtIndex:indexPath.row];
    } else {
        assetCollection = [self.albums objectAtIndex:indexPath.row];
    }
    
    ImagePickerPhotosViewController *photoViewController = [ImagePickerPhotosViewController new];
    photoViewController.delegate = self;
    photoViewController.assetCollection = assetCollection;
    [self.navigationController pushViewController:photoViewController animated:YES];
    if ([self.delegate respondsToSelector:@selector(imagePickerSetsViewController:userDidSelectAssetCollection:)]) {
        [self.delegate imagePickerSetsViewController:self userDidSelectAssetCollection:assetCollection];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kImagePickerSetsTableViewCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 15.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *viewHeader = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, tableView.frame.size.width, 25.f)];
    
    CGFloat titleLeftPadding = kHeaderTitlePhoneLeftPadding;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleLeftPadding, 0.f, 136.f, 21.f)];
    
    titleLabel.font = [UIFont boldSystemFontOfSize:14.f];
    titleLabel.textColor = [UIColor grayColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    
    if (section == 0) {
        titleLabel.text = [NSLocalizedString(@"smart_albums", nil) uppercaseString];
    } else {
        if (self.albums.count > 0) {
            titleLabel.text = [NSLocalizedString(@"albums", nil) uppercaseString];
        } else {
            titleLabel.text = @"";
        }

    }
    
    [titleLabel sizeToFit];
    [viewHeader addSubview:titleLabel];
    
    return viewHeader;
}

#pragma mark - PickerPhotos delegate methods

- (void)userDidDismissImagePickerViewController:(UIViewController *)viewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)imagePickerPhotosViewController:(UIViewController *)viewController userDidSelectAsset:(PHAsset *)asset
{
    [self.delegate imagePickerSetsViewController:self userDidSelectAsset:asset];
}

#pragma mark - Custom Accessors

- (NSMutableArray *)albums
{
    if (!_albums) {
        _albums = [NSMutableArray array];
    }
    
    return _albums;
}

- (NSMutableArray *)smartAlbums
{
    if (!_smartAlbums) {
        _smartAlbums = [NSMutableArray array];
    }
    
    return _smartAlbums;
}
@end
