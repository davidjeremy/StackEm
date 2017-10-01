//
//  ImagePickerSetsTableViewCell.m
//  500px
//
//  Created by Jerome Scheer on 20/04/15.
//  Copyright (c) 2015 500px. All rights reserved.
//

#import "ImagePickerSetsTableViewCell.h"

static const CGFloat kLabelsTrailingSpaceDefault = 14.f;
static const CGFloat kLabelsTrailingSpaceDisclosureIndicatorHidden = 0.f;

@interface ImagePickerSetsTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *disclosureIndicatorImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subTitleTrailingSpaceConstraint;
@end

@implementation ImagePickerSetsTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    self.title.textColor = [UIColor darkGrayColor];
    self.subTitle.textColor = [UIColor grayColor];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.title.text = @"";
    self.subTitle.text = @"";
    self.posterImageView.image = nil;
    self.userInteractionEnabled = YES;
}

#pragma mark - Custom accessors

- (void)setHideDisclosureIndicator:(BOOL)hideDisclosureIndicator
{
    _hideDisclosureIndicator = hideDisclosureIndicator;
    self.disclosureIndicatorImageView.hidden = hideDisclosureIndicator;
    
    if (_hideDisclosureIndicator) {
        self.titleTrailingSpaceConstraint.constant = kLabelsTrailingSpaceDisclosureIndicatorHidden;
        self.subTitleTrailingSpaceConstraint.constant = kLabelsTrailingSpaceDisclosureIndicatorHidden;
    } else {
        self.titleTrailingSpaceConstraint.constant = kLabelsTrailingSpaceDefault;
        self.subTitleTrailingSpaceConstraint.constant = kLabelsTrailingSpaceDefault;
    }
    
}

@end
