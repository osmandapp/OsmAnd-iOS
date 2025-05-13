//
//  OAShapesTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"

@protocol OAShapesTableViewCellDelegate <NSObject>

- (void)iconChanged:(NSInteger)tag;

@end

@interface OAShapesTableViewCell : OACollectionSingleLineTableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray *iconNames;
@property (nonatomic) NSArray *contourIconNames;
@property (nonatomic) NSInteger currentColor;
@property (nonatomic) NSInteger currentIcon;
@property (nonatomic) NSString *backgroundShapeName;

@property (nonatomic, weak) id<OAShapesTableViewCellDelegate> shapesDelegate;

- (void)topButtonVisibility:(BOOL)show;
- (void)descriptionLabelStackViewVisibility:(BOOL)show;
- (void)separatorVisibility:(BOOL)show;
- (void)topRightOffset:(CGFloat)value;
- (void)updateIconWith:(NSInteger)tag;

@end
