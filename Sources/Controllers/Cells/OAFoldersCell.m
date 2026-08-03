//
//  OAFoldersCell.m
//  OsmAnd
//
//  Created by nnngrach on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFoldersCell.h"
#import "OAFoldersCollectionView.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAFoldersCell ()

@property (weak, nonatomic) IBOutlet UIView *rightActionContainerView;
@property (weak, nonatomic) IBOutlet UIView *rightActionDividerView;

@end

@implementation OAFoldersCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.rightActionDividerView.backgroundColor = [UIColor adaptiveSeparator];
}

- (void)rightActionButtonVisibility:(BOOL)show
{
    self.rightActionContainerView.hidden = !show;
}

@end
