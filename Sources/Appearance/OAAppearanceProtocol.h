//
//  OAAppearanceProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OAButtonStyle)
{
    OAButtonStyleRegular = 0,
    OAButtonStyleLeadingSideDock,
    OAButtonStyleTrailingSideDock,
    OAButtonStyleTopSideDock,
    OAButtonStyleBottomSideDock,
};

@protocol OAAppearanceProtocol <NSObject>
@required

- (UIImage*)hudRoundButtonBackgroundForButton:(UIButton*)button;
- (UIImage*)hudButtonBackgroundForStyle:(OAButtonStyle)style;

@end
