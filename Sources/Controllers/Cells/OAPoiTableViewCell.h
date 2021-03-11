//
//  OAPoiTableViewCell.h
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAPoiTableViewCellDelegate <NSObject>

- (void)poiChanged:(NSInteger)tag;

@end

@interface OAPoiTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray *dataArray;
@property (nonatomic) NSInteger currentColor;
@property (nonatomic) NSInteger currentIcon;

@property (nonatomic, weak) id<OAPoiTableViewCellDelegate> delegate;

@end
