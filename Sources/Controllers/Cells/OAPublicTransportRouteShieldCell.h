//
//  OAPublicTransportRouteShieldCell.h
//  OsmAnd
//
//  Created by Paul on 24/03/20.
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OATransportShieldDelegate <NSObject>

@required

- (void) onShileldPressed:(NSInteger)index;

@end

@interface OAPublicTransportRouteShieldCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIView *routeLineView;
@property (weak, nonatomic) IBOutlet UIView *routeShieldContainerView;

@property (nonatomic) id<OATransportShieldDelegate> delegate;

- (void) setShieldColor:(UIColor *)color;

@end
