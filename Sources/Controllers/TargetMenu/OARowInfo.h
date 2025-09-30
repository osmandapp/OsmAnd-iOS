//
//  OARowInfo.h
//  OsmAnd
//
//  Created by nnngrach on 20.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OARowInfo, OACollapsableView;

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
@property (nonatomic, nullable) OACollapsableView *collapsableView;
@property (nonatomic) BOOL collapsed;
@property (nonatomic, copy) void (^collapsedChangedCallback)(BOOL collapsed);
@property (nonatomic) int order;
@property (nonatomic) NSString *typeName;

@property (nonatomic) int height;
@property (nonatomic) BOOL moreText;
@property (nonatomic, strong, readonly) NSMutableArray<NSDictionary *> *detailsArray;

@property (weak, nonatomic) id<OARowInfoDelegate> delegate;

- (instancetype) initWithKey:(nullable NSString *)key icon:(nullable UIImage *)icon textPrefix:(nullable NSString *)textPrefix text:(NSString *)text textColor:(nullable UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl;

- (int) getRawHeight;
- (UIFont *) getFont;
- (void)setDetailsArray:(NSMutableArray<NSDictionary *> *)detailsArray;

@end

NS_ASSUME_NONNULL_END
