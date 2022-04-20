//
//  OACustomButton.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACustomButton : UIButton

- (instancetype)initBySystemTypeWithTapToCopy:(BOOL)tapToCopy longPressToCopy:(BOOL)longPressToCopy;

@property (nonatomic, assign) BOOL centerVertically;
@property (nonatomic, assign) BOOL extraSpacing;

- (void)applyVerticalLayout;

@end
