//
//  OAMapWidgetRegInfo.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATextInfoWidget, OAWidgetState, OAApplicationMode;

@interface OAMapWidgetRegInfo : NSObject

@property (nonatomic) OATextInfoWidget *widget;
@property (nonatomic) NSString *key;
@property (nonatomic) BOOL left;
@property (nonatomic) int priorityOrder;

@property (nonatomic) NSMutableSet<OAApplicationMode *> *visibleCollapsible;
@property (nonatomic) NSMutableSet<OAApplicationMode *> *visibleModes;

- (instancetype) initWithKey:(NSString *)key widget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message priorityOrder:(int)priorityOrder left:(BOOL)left;

- (instancetype) initWithKey:(NSString *)key widget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState priorityOrder:(int)priorityOrder left:(BOOL)left;

- (NSString *) getImageId;
- (NSString *) getMessage;
- (NSArray<NSString *> *) getImageIds;
- (NSArray<NSString *> *) getMessages;
- (NSArray<NSString *> *) getItemIds;
- (void) changeState:(NSString *)stateId;

- (BOOL) visibleCollapsed:(OAApplicationMode *)mode;
- (BOOL) visible:(OAApplicationMode *)mode;
- (OAMapWidgetRegInfo *) required:(NSArray<OAApplicationMode *> *)modes;

- (NSComparisonResult) compare:(OAMapWidgetRegInfo *)another;

@end
