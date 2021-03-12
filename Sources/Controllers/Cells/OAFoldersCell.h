//
//  OAFoldersCell.h
//  OsmAnd
//
//  Created by nnngrach on 09.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAFoldersCellDelegate <NSObject>

@required

- (void) onItemSelected:(int)index type:(NSString *)type;

@end

@interface OAFoldersCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) id<OAFoldersCellDelegate> delegate;

- (void) setValues:(NSArray<NSDictionary *> *)values withSelectedIndex:(int)index;


@end
