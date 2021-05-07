//
//  OAFoldersCell.h
//  OsmAnd
//
//  Created by nnngrach on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "OACollectionViewCellState.h"

@protocol OAFoldersCellDelegate <NSObject>

@required

- (void) onItemSelected:(int)index type:(NSString *)type;

@end

@interface OAFoldersCell : OABaseCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) id<OAFoldersCellDelegate> delegate;
@property (weak, nonatomic) OACollectionViewCellState *state;
@property (nonatomic) NSIndexPath *cellIndex;

- (void) setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(int)index;
- (void) updateContentOffset;

@end
