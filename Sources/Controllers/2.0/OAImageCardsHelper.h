//
//  OAImageCardsHelper.h
//  OsmAnd
//
//  Created by nnngrach on 09.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OATargetPoint.h"
#import "OACollapsableView.h"

@class OARowInfo, OATargetMenuViewController;

@protocol OARowInfoDelegate <NSObject>

@optional

- (void) onRowClick:(OATargetMenuViewController *)sender rowInfo:(OARowInfo *)rowInfo;

@end

@interface OARowInfo : NSObject

@property (nonatomic) NSString *key;
@property (nonatomic) UIImage *icon;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *textPrefix;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) BOOL isText;
@property (nonatomic) BOOL isHtml;
@property (nonatomic) BOOL needLinks;
@property (nonatomic) BOOL isPhoneNumber;
@property (nonatomic) BOOL isUrl;
@property (nonatomic) BOOL collapsable;
@property (nonatomic) OACollapsableView *collapsableView;
@property (nonatomic) BOOL collapsed;
@property (nonatomic) int order;
@property (nonatomic) NSString *typeName;

@property (nonatomic) int height;
@property (nonatomic) BOOL moreText;

@property (weak, nonatomic) id<OARowInfoDelegate> delegate;

- (instancetype) initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl;

- (int) getRawHeight;
- (UIFont *) getFont;

@end


@interface OAImageCardsHelper : NSObject

@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic) id targetObj;

- (OARowInfo *) addNearbyImagesIfNeeded;
- (void)sendNearbyImagesRequest:(OARowInfo *)nearbyImagesRowInfo;

@end
