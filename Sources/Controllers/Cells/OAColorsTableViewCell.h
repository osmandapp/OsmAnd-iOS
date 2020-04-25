//
//  OAColorsTableViewCell.h
//  OsmAnd
//
//  Created by igor on 06.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAColorsTableViewCellDelegate <NSObject>

- (void)colorChanged:(NSInteger)tag;

@end

@interface OAColorsTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray *dataArray;
@property (nonatomic) NSInteger currentColor;

@property (nonatomic, weak) id<OAColorsTableViewCellDelegate> delegate;

@end

