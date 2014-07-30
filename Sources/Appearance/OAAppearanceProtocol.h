//
//  OAAppearanceProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, OAHudViewStyle)
{
    OAHudViewStyleRegular = 0,

    OAHudViewStyleLeadingSideDock,
    OAHudViewStyleTrailingSideDock,
    OAHudViewStyleTopSideDock,
    OAHudViewStyleBottomSideDock,

    OAHudViewStyleTopLeadingSideDock,
    OAHudViewStyleBottomLeadingSideDock,
    OAHudViewStyleTopTrailingSideDock,
    OAHudViewStyleBottomTrailingSideDock
};

@protocol OAAppearanceProtocol <NSObject>
@required

- (UIImage*)hudViewRoundBackgroundWithRadius:(CGFloat)radius;
- (UIImage*)hudViewBackgroundForStyle:(OAHudViewStyle)style;

@end
