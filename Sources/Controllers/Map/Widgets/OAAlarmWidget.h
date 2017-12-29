//
//  OAAlarmWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAWidgetListener;

@interface OAAlarmWidget : UIView

@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (BOOL) updateInfo;

@end
