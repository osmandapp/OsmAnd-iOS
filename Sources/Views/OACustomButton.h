//
//  OACustomButton.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OACustomButtonDelegate <NSObject>

@optional

- (void)onButtonTapped:(NSInteger)tag;
- (void)onButtonLongPressed:(NSInteger)tag;

@end

@interface OACustomButton : UIButton

@property (nonatomic, assign) BOOL centerVertically;
@property (nonatomic, assign) BOOL extraSpacing;

@property (nonatomic) id<OACustomButtonDelegate> delegate;

- (void)applyVerticalLayout;

@end
