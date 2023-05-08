//
//  OACollectionSingleLineTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 24.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseCollectionHandler.h"
#import "OASimpleTableViewCell.h"

@interface OACollectionSingleLineTableViewCell : UITableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *button;

- (void)setCollectionHandler:(OABaseCollectionHandler *)collectionHandler;
- (OABaseCollectionHandler *)getCollectionHandler;

- (void)buttonVisibility:(BOOL)show;

- (void)anchorContent:(EOATableViewCellContentStyle)style;

@end
