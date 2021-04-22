//
//  OAHorizontalCollectionViewIconCell.h
//  OsmAnd
//
//  Created by nnngrach on 08.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACollectionViewCellState.h"

@protocol OAFolderCardsCellDelegate <NSObject>

@required

- (void) onItemSelected:(NSInteger)index;
- (void) onAddFolderButtonPressed;

@end

@interface OAFolderCardsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) id<OAFolderCardsCellDelegate> delegate;
@property (weak, nonatomic) OACollectionViewCellState *state;
@property (nonatomic) NSIndexPath *cellIndex;

- (void) setValues:(NSArray<NSString *> *)values sizes:(NSArray<NSNumber *> *)sizes colors:(NSArray<UIColor *> *)colors addButtonTitle:(NSString *)addButtonTitle withSelectedIndex:(int)index;
- (void) setupInitialOffsetForSelectedIndex:(NSInteger)selectedIndex;
- (CGPoint) calculateOffset:(NSInteger)index;
- (void) updateContentOffset;

@end
