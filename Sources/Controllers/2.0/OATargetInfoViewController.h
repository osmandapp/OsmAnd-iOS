//
//  OATargetInfoViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OACollapsableView.h"

@class OARowInfo;

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

@interface OATargetInfoViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSArray<OARowInfo *> *additionalRows;

- (BOOL) needCoords;
- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) rebuildRows;

+ (UIImage *) getIcon:(NSString *)fileName;

@end
