//
//  OAIconsTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@protocol OAShapesTableViewCellDelegate <NSObject>

- (void)iconChanged:(NSInteger)tag;

@end

@interface OAShapesTableViewCell : OABaseCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray *iconNames;
@property (nonatomic) NSArray *contourIconNames;
@property (nonatomic) NSInteger currentColor;
@property (nonatomic) NSInteger currentIcon;
@property (nonatomic) NSString *backgroundShapeName;

@property (nonatomic, weak) id<OAShapesTableViewCellDelegate> delegate;

@end
