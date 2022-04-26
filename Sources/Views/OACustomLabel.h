//
//  OACustomLabel.h
//  OsmAnd
//
//  Created by Skalii on 15.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OACustomLabelDelegate <NSObject>

- (void)onLabelTapped:(NSInteger)tag;
- (void)onLabelLongPressed:(NSInteger)tag;

@end

@interface OACustomLabel : UILabel

@property (nonatomic) id<OACustomLabelDelegate> delegate;

@end
