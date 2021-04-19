//
//  OAPoiTableViewCell.h
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACollectionViewCellState : NSObject

@property (nonatomic) CGPoint contenOffset;

+ (CGPoint) calculateShowingOffset:(NSInteger)index labels:(NSArray<NSString *> *)labels;

@end


@protocol OAPoiTableViewCellDelegate <NSObject>

- (void) onPoiCategorySelected:(NSString *)category index:(NSInteger)index;
- (void) onPoiSelected:(NSString *)poiName;

@end

@interface OAPoiTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

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
@property (nonatomic) NSInteger currentCategoryIndex;

@property (nonatomic, weak) id<OAPoiTableViewCellDelegate> delegate;
@property (nonatomic) OACollectionViewCellState *state;

- (void) updateContentOffset;

@end
