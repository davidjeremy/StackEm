//
//  ImagePickerSetsTableViewCell.h
//  500px
//
//  Created by Jerome Scheer on 20/04/15.
//  Copyright (c) 2015 500px. All rights reserved.
//

@import UIKit;

static const CGFloat kImagePickerSetsTableViewCellHeight = 80.f;

@interface ImagePickerSetsTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *posterImageView;
@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *subTitle;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (nonatomic) BOOL hideDisclosureIndicator;

@end
