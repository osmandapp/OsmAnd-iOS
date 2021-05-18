//
//  OAQuickSearchButtonListItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchListItem.h"

typedef void(^OACustomSearchButtonOnClick)(id sender);

@interface OAQuickSearchButtonListItem : OAQuickSearchListItem

@property (nonatomic) UIImage *icon;
@property (nonatomic) NSString *text;
@property (nonatomic) NSAttributedString *attributedText;
@property (nonatomic) OACustomSearchButtonOnClick onClickFunction;

- (instancetype)initWithIcon:(UIImage *)icon text:(NSString *)text onClickFunction:(OACustomSearchButtonOnClick)onClickFunction;
- (instancetype)initWithIcon:(UIImage *)icon text:(NSString *)text actionButton:(BOOL)actionButton onClickFunction:(OACustomSearchButtonOnClick)onClickFunction;
- (instancetype)initWithIcon:(UIImage *)icon attributedText:(NSAttributedString *)attributedText onClickFunction:(OACustomSearchButtonOnClick)onClickFunction;

- (NSAttributedString *)getAttributedName;
- (void)onClick;

@end
