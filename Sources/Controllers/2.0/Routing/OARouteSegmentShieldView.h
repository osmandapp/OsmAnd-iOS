//
//  OARouteSegmentShieldView.h
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

@interface OARouteSegmentShieldView : UIView

@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *shieldImage;
@property (weak, nonatomic) IBOutlet UILabel *shieldLabel;

- (instancetype) initWithColor:(UIColor *)color title:(NSString *)title iconName:(NSString *)iconName type:(EOATransportShiledType)type;

+ (CGFloat) getViewWidth:(NSString *)text;

@end
