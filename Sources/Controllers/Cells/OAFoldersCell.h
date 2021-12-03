//
//  OAFoldersCell.h
//  OsmAnd
//
//  Created by nnngrach on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACollectionViewCellState.h"

@protocol OAFoldersCellDelegate <NSObject>

@required

- (void) onItemSelected:(NSInteger)index type:(NSString *)type;

@end

@interface OAFoldersCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) id<OAFoldersCellDelegate> foldersDelegate;
@property (weak, nonatomic) OACollectionViewCellState *state;
@property (nonatomic) NSIndexPath *cellIndex;

- (void) setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(NSInteger)index;
- (void) updateContentOffset;

@end
