//
//  OANauticalDepthParametersViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.11.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAMapStyleParameter;

@protocol OANauticalDepthParametersDelegate <NSObject>

@required

- (void)onValueSelected:(OAMapStyleParameter *)parameter;

@end

@interface OANauticalDepthParametersViewController : OABaseNavbarViewController

- (instancetype)initWithParameter:(OAMapStyleParameter *)parameter;

@property (nonatomic, weak) id<OANauticalDepthParametersDelegate> depthDelegate;

@end
