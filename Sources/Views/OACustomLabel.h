//
//  OACustomLabel.h
//  OsmAnd
//
//  Created by Skalii on 15.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACustomLabel : UILabel

- (instancetype)initWithFrame:(CGRect)frame tapToCopy:(BOOL)tapToCopy longPressToCopy:(BOOL)longPressToCopy;

@end
