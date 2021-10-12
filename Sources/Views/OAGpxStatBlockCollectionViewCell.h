//
//  OAGpxStatBlockCollectionViewCell.h
//  OsmAnd
//
//  Created by Skalii on 17.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAGpxStatBlockCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *valueView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noSeparatorConstraint;

@end
