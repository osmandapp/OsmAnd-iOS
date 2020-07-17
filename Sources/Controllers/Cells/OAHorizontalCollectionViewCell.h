//
//  OAHorizontalCollectionViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAHorizontalCollectionViewCellDelegate <NSObject>

- (void)valueChanged:(NSInteger)tag;

@end

@interface OAHorizontalCollectionViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) NSArray *dataArray;
@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic, weak) id<OAHorizontalCollectionViewCellDelegate> delegate;

@end
