//
//  OACollectionViewCell.h
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "MaterialTextFields.h"

@protocol OACollectionViewCellDelegate <NSObject>

@required

- (void) onItemSelected:(NSString *) key point:(id)point;

@end

@interface OACollectionViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) id<OACollectionViewCellDelegate> delegate;

- (void) setData:(NSArray *)data;

@end
