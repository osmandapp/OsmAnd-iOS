//
//  OAPoiTableViewCell.h
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "OACollectionViewCellState.h"

@protocol OAPoiTableViewCellDelegate <NSObject>

- (void) onPoiCategorySelected:(NSString *)category index:(NSInteger)index;
- (void) onPoiSelected:(NSString *)poiName;

@end

@interface OAPoiTableViewCell : OABaseCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;
@property (weak, nonatomic) IBOutlet UICollectionView *categoriesCollectionView;

@property (nonatomic) NSDictionary<NSString *, NSArray<NSString *> *> *poiData;
@property (nonatomic) NSInteger currentColor;
@property (nonatomic) NSString *currentIcon;
@property (nonatomic) NSArray *categoryDataArray;
@property (nonatomic) NSString *currentCategory;

@property (nonatomic, weak) id<OAPoiTableViewCellDelegate> delegate;
@property (weak, nonatomic) OACollectionViewCellState *state;
@property (nonatomic) NSIndexPath *cellIndex;

- (void) updateContentOffset;

@end
