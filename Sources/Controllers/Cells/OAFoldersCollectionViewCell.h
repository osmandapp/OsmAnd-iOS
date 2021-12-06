//
//  OAFoldersCollectionViewCell.h
//  OsmAnd
//
//  Created by nnngrach on 08.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAFoldersCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *labelWithIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *labelNoIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *centerAlignIconConstraint;

- (void)showImage:(BOOL)show;

@end
