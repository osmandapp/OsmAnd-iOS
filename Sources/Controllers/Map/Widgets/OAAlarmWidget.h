//
//  OAAlarmWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseWidgetView.h"

@class OAAlarmInfo, OADrivingRegion;

@interface OAAlarmWidgetInfo : NSObject

@property (nonatomic) OAAlarmInfo *alarm;
@property (nonatomic, assign) BOOL americanType;
@property (nonatomic, assign) BOOL isCanadianRegion;
@property (nonatomic) NSString *locImgId;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *bottomText;
@property (nonatomic) OADrivingRegion *region;

@end

@interface OAAlarmWidget : OABaseWidgetView

@end
