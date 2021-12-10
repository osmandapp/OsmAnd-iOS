//
//  OAFoldersCell.h
//  OsmAnd
//
//  Created by nnngrach on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACollectionViewCellState.h"

@class OAFoldersCollectionView;

@protocol OAFoldersCellDelegate;

@interface OAFoldersCell : UITableViewCell

@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *collectionView;

@end
