//
//  OAShareMenuActivity.h
//  OsmAnd
//
//  Created by Skalii on 11.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OAShareMenuActivityType)
{
    OAShareMenuActivityClipboard = 0,
    OAShareMenuActivityCopyAddress,
    OAShareMenuActivityCopyPOIName,
    OAShareMenuActivityCopyCoordinates,
    OAShareMenuActivityGeo
};

@protocol OAShareMenuDelegate

- (void)onCopy:(OAShareMenuActivityType)type;

@end

@interface OAShareMenuActivity : UIActivity

- (instancetype)initWithType:(OAShareMenuActivityType)type;

@property (nonatomic, weak) id<OAShareMenuDelegate> delegate;

@end