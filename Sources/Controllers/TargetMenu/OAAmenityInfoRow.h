//
//  OAAmenityInfoRow.h
//  OsmAnd
//
//  Created by nnngrach on 20.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAAmenityInfoRow, OACollapsableView;

@protocol OARowInfoDelegate <NSObject>

@optional
- (void) onRowClick:(OATargetMenuViewController *)sender rowInfo:(OAAmenityInfoRow *)rowInfo;

@end

@interface OAAmenityInfoRow : NSObject

@property (nonatomic) NSString *key;
@property (nonatomic) UIImage *icon;
@property (nonatomic) NSString *textPrefix;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *hiddenUrl;
@property (nonatomic, nullable) OACollapsableView *collapsableView;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) BOOL isWiki;
@property (nonatomic) BOOL isText;
@property (nonatomic) BOOL needLinks;
@property (nonatomic) BOOL isPhoneNumber;
@property (nonatomic) BOOL isUrl;
@property (nonatomic) NSInteger order;
@property (nonatomic) NSString *typeName;
@property (nonatomic) BOOL matchWidthDivider;
@property (nonatomic) NSInteger textLinesLimit;

//TODO: Don't exists in Android
@property (nonatomic) BOOL isHtml;

@property (nonatomic) BOOL collapsed;
@property (nonatomic, copy) void (^collapsedChangedCallback)(BOOL collapsed);

@property (nonatomic) int height;
@property (nonatomic) BOOL moreText;
@property (nonatomic, strong, readonly) NSMutableArray<NSDictionary *> *detailsArray;

@property (weak, nonatomic) id<OARowInfoDelegate> delegate;

//TODO: delete? and use new init() ?
- (instancetype) initWithKey:(nullable NSString *)key icon:(nullable UIImage *)icon textPrefix:(nullable NSString *)textPrefix text:(NSString *)text textColor:(nullable UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(NSInteger)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl;

//TODO: just delete?
- (instancetype) initWithKey:(NSString *)key icon:(nullable UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(nullable UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks collapsable:(nullable OACollapsableView *)collapsable order:(NSInteger)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl;

//TODO: test new version?
- (instancetype) initWithKey:(NSString * _Nullable)key icon:(UIImage * _Nullable)icon textPrefix:(NSString * _Nullable)textPrefix text:(NSString * _Nullable)text hiddenUrl:(NSString * _Nullable)hiddenUrl collapsableView:(OACollapsableView * _Nullable)collapsableView textColor:(UIColor * _Nullable)textColor isWiki:(BOOL)isWiki isText:(BOOL)isText needLinks:(BOOL)needLinks isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl order:(NSInteger)order name:(NSString * _Nullable)name matchWidthDivider:(BOOL)matchWidthDivider textLinesLimit:(int)textLinesLimit;

- (BOOL) collapsable;

- (int) getRawHeight;
- (UIFont *) getFont;
- (void)setDetailsArray:(NSMutableArray<NSDictionary *> *)detailsArray;

@end

NS_ASSUME_NONNULL_END
