//
//  OAMenuSimpleCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMenuSimpleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (nonatomic) IBOutlet NSLayoutConstraint *textBottomMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrTopMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imgHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imgWidthPrimary;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTopPrimaryMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTopSecondaryMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomPrimaryMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomSecondaryMargin;

- (void)changeHeight:(BOOL)higher;

@end
