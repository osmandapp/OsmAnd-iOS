//
//  OAPublicTransportShieldsView.h
//  OsmAnd
//
//  Created by Paul on 13.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOATransportShiledType)
{
    EOATransportShiledPedestrian = 0,
    EOATransportShiledTransport
};

NS_ASSUME_NONNULL_BEGIN

@interface OAPublicTransportShieldsView : UIView

- (void)setData:(NSNumber *)data;

@end

NS_ASSUME_NONNULL_END
