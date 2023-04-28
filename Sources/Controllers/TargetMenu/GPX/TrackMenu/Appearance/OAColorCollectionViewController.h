//
//  OAColorCollectionViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OACollectionCellDelegate;

@interface OAColorCollectionViewController : OABaseNavbarViewController

- (instancetype)initWithHexKeys:(NSMutableArray<NSString *> *)hexKeys selectedHexKey:(NSString *)selectedHexKey;

@property(nonatomic, weak) id<OACollectionCellDelegate>delegate;

@end
