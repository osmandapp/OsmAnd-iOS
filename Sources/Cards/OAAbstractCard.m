//
//  OAAbstractCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAbstractCard.h"

@implementation OAAbstractCard


- (UICollectionViewCell *) build:(UICollectionView *) collectionView indexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (void) onCardPressed:(OAMapPanelViewController *) mapPanel
{
    return;
}

- (void) applyShadowToCell:(UICollectionViewCell *)cell
{
    cell.clipsToBounds = NO;
    cell.layer.cornerRadius = 6.0;
    cell.layer.shadowOffset = CGSizeMake(0, 1);
    cell.layer.shadowOpacity = 0.3;
    cell.layer.shadowRadius = 2.0;
}

@end
