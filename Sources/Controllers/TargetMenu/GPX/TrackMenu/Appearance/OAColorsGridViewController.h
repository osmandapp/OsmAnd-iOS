//
//  OAColorsGridViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OACollectionCellDelegate;

@interface OAColorsGridViewController : OABaseNavbarViewController

- (instancetype)initWithColors:(NSMutableArray<NSNumber *> *)colors selectedColor:(NSInteger)selectedColor;

@property(nonatomic, weak) id<OACollectionCellDelegate>delegate;

@end
