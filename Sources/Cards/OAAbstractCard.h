//
//  OAAbstractCard.h
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class OAMapPanelViewController;

@interface OAAbstractCard : NSObject

- (UICollectionViewCell *) build:(UICollectionView *) collectionView indexPath:(NSIndexPath *)indexPath;
- (void) onCardPressed:(OAMapPanelViewController *) mapPanel;

- (void) applyShadowToCell:(UICollectionViewCell *)cell;

@end

NS_ASSUME_NONNULL_END
