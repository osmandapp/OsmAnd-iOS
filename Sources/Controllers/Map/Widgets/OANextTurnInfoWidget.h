//
//  OANextTurnInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

#define kNextTurnInfoWidgetHeight 112

@interface OANextTurnInfoWidget : OATextInfoWidget

- (instancetype) initWithHorisontalMini:(BOOL)horisontalMini nextNext:(BOOL)nextNext;

@end
