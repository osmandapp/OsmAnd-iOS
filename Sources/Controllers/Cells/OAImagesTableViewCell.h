//
//  OAImagesTableViewCell.h
//  OsmAnd
//
//  Created by nnngrach on 09.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAImagesTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewWidth;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewLeftOffset;

@property (nonatomic) NSArray<UIImage *> *images;

@end
