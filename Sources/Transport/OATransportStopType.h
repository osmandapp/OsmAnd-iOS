//
//  OATransportStopType.h
//  OsmAnd
//
//  Created by Alexey on 11/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOATransportStopType)
{
    TST_BUS = 0,
    TST_FERRY,
    TST_FUNICULAR,
    TST_LIGHT_RAIL,
    TST_MONORAIL,
    TST_RAILWAY,
    TST_SHARE_TAXI,
    TST_TRAIN,
    TST_TRAM,
    TST_TROLLEYBUS,
    TST_SUBWAY
};

@interface OATransportStopType : NSObject

@property (nonatomic, readonly) EOATransportStopType type;
@property (nonatomic, readonly) NSString *resId;
@property (nonatomic, readonly) NSString *topResId;
@property (nonatomic, readonly) NSString *renderAttr;
@property (nonatomic, readonly) NSString *resName;

- (instancetype) initWithType:(EOATransportStopType)type;

+ (NSString *) getResId:(EOATransportStopType)type;
+ (NSString *) getTopResId:(EOATransportStopType)type;
+ (NSString *) getRenderAttr:(EOATransportStopType)type;
+ (NSString *) getResName:(EOATransportStopType)type;

+ (BOOL) isTopType:(EOATransportStopType)type;
+ (OATransportStopType *) findType:(NSString *)typeName;
    
@end
