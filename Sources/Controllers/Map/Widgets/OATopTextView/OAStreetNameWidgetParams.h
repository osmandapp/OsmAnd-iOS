//
//  OAStreetNameWidgetParams.h
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 05.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OATurnDrawable.h"
#import "OACurrentStreetName.h"

@interface OAStreetNameWidgetParams : NSObject

@property (nonatomic) OACurrentStreetName *streetName;
@property (nonatomic) BOOL showClosestWaypointFirstInAddress;

- (instancetype)initWithTurnDrawable:(OATurnDrawable *)turnDrawable calc1:(OANextDirectionInfo *)calc1 showNextTurn:(BOOL)showNextTurn;

@end
