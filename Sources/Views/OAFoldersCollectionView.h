//
//  OAFoldersCollectionView.h
//  OsmAnd
//
//  Created by Skalii on 06.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OACollectionViewCellState;

@protocol OAFoldersCellDelegate <NSObject>

@required

- (void)onItemSelected:(NSInteger)index;

@end

@interface OAFoldersCollectionView : UICollectionView

@property (nonatomic) id<OAFoldersCellDelegate> foldersDelegate;
@property (weak, nonatomic) OACollectionViewCellState *state;
@property (nonatomic) NSIndexPath *cellIndex;

- (void)setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(NSInteger)index;
- (void)setSelectedIndex:(NSInteger)index;
- (NSInteger)getSelectedIndex;
- (void)updateContentOffset;

@end
