//
//  OASeveralViewsTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOALocationType)
{
    EOALocationTypeRest = 0,
    EOALocationTypeMoving
};

@protocol OALocationIconsTableViewCellDelegate <NSObject>

- (void) mapIconChanged:(NSInteger)newValue type:(EOALocationType)locType;

@end

@interface OALocationIconsTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (nonatomic) NSArray<UIImage *> *dataArray;
@property (nonatomic) NSInteger currentColor;
@property (nonatomic) EOALocationType locationType;
@property (nonatomic) NSInteger selectedIndex;

@property (nonatomic, weak) id<OALocationIconsTableViewCellDelegate> delegate;

@end
