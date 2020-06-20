//
//  OASeveralViewsTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OASeveralViewsTableViewCellDelegate <NSObject>

- (void)mapIconChanged:(NSInteger)tag;

@end

@interface OASeveralViewsTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray *dataArray;
@property (nonatomic) NSInteger currentColor;

@property (nonatomic, weak) id<OASeveralViewsTableViewCellDelegate> delegate;

@end
