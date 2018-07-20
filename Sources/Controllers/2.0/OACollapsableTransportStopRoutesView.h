//
//  OACollapsableTransportStopRoutesView.h
//  OsmAnd
//
//  Created by Alexey on 13/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OATransportStopRoute;

@interface OACollapsableTransportStopRoutesView : OACollapsableView

@property (nonatomic) NSArray<OATransportStopRoute *> *routes;

@end
