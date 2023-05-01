//
//  OAColorCollectionViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAColorCollectionDelegate

- (void)onHexKeySelected:(NSString *)selectedHexKey;
- (NSArray<NSString *> *)updateColors;
- (BOOL)isDefaultColor:(NSString *)hexKey;

@end

@interface OAColorCollectionViewController : OABaseNavbarViewController

- (instancetype)initWithHexKeys:(NSArray<NSString *> *)hexKeys selectedHexKey:(NSString *)selectedHexKey;

@property(nonatomic, weak) id<OAColorCollectionDelegate>delegate;

@end
