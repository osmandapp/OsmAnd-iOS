//
//  OAIconsTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAIconsTableViewCellDelegate <NSObject>

- (void)iconChanged:(NSInteger)tag;

@end

@interface OAIconsTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray *dataArray;
@property (nonatomic) NSInteger currentColor;
@property (nonatomic) NSInteger currentIcon;

@property (nonatomic, weak) id<OAIconsTableViewCellDelegate> delegate;

@end
