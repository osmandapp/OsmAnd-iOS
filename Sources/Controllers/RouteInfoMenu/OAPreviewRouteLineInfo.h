//
//  OAPreviewRouteLineInfo.h
//  OsmAnd
//
//  Created by Skalii on 20.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAColoringType;

@interface OAPreviewRouteLineInfo : NSObject

@property (nonatomic, assign) NSInteger customColorDay;
@property (nonatomic, assign) NSInteger customColorNight;
@property (nonatomic) OAColoringType *coloringType;
@property (nonatomic) NSString *routeInfoAttribute;
@property (nonatomic) NSString *width;
@property (nonatomic, assign) BOOL showTurnArrows;

- (instancetype)initWithCustomColorDay:(NSInteger)customColorDay
                      customColorNight:(NSInteger)customColorNight
                          coloringType:(OAColoringType *)coloringType
                    routeInfoAttribute:(NSString *)routeInfoAttribute
                                 width:(NSString *)width
                        showTurnArrows:(BOOL)showTurnArrows;

- (void)setCustomColor:(NSInteger)color nightMode:(BOOL)nightMode;
- (NSInteger)getCustomColor:(BOOL)nightMode;

@end
