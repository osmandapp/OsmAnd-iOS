//
//  OAAmenityInfoRow.m
//  OsmAnd Maps
//
//  Created by nnngrach on 20.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAAmenityInfoRow.h"
#import "OACollapsableView.h"

@implementation OAAmenityInfoRow

- (instancetype) initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(NSInteger)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl
{
    self = [super init];
    if (self)
    {
        _key = key;
        _icon = icon;
        _icon = [_icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _textPrefix = textPrefix;
        _text = text;
        _textColor = textColor;
        _isText = isText;
        _needLinks = needLinks;
        _order = order;
        _typeName = typeName;
        _isPhoneNumber = isPhoneNumber;
        _isUrl = isUrl;
        _detailsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key icon:(nullable UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(nullable UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks collapsable:(nullable OACollapsableView *)collapsable order:(NSInteger)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl
{
    self = [self initWithKey:key icon:icon textPrefix:textPrefix text:text textColor:textColor isText:isText needLinks:needLinks order:order typeName:typeName isPhoneNumber:isPhoneNumber isUrl:isUrl];
    if (self)
    {
        self.collapsableView = collapsable;
    }
    return self;
}

- (instancetype) initWithKey:(NSString *)key icon:(nullable UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text hiddenUrl:(NSString *)hiddenUrl collapsableView:(nullable OACollapsableView *)collapsableView textColor:(nullable UIColor *)textColor isWiki:(BOOL)isWiki isText:(BOOL)isText needLinks:(BOOL)needLinks isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl order:(NSInteger)order name:(NSString *)name matchWidthDivider:(BOOL)matchWidthDivider textLinesLimit:(int)textLinesLimit
{
    self = [super init];
    if (self)
    {
        _key = key;
        _icon = icon;
        _icon = [_icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _textPrefix = textPrefix;
        _text = text;
        _hiddenUrl = hiddenUrl;
        _collapsableView = collapsableView;
        _textColor = textColor;
        _isWiki = isWiki;
        _isText = isText;
        _needLinks = needLinks;
        _isPhoneNumber = isPhoneNumber;
        _isUrl = isUrl;
        _order = order;
        _typeName = name;
        _matchWidthDivider = matchWidthDivider;
        _textLinesLimit = textLinesLimit;
        _detailsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BOOL) collapsable
{
    return _collapsableView;
}

- (int) height
{
    if ([self collapsable] && _collapsableView && !_collapsed)
        return _height + _collapsableView.frame.size.height;
    else
        return _height;
}

- (int) getRawHeight
{
    return _height;
}

- (UIFont *) getFont
{
    return [UIFont scaledSystemFontOfSize:17.0 weight:_isUrl ? UIFontWeightMedium : UIFontWeightRegular];
}

- (void)setCollapsed:(BOOL)collapsed
{
    if (_collapsed != collapsed)
    {
        _collapsed = collapsed;
        
        if (self.collapsedChangedCallback)
            self.collapsedChangedCallback(collapsed);
    }
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OAAmenityInfoRow *item = (OAAmenityInfoRow *) object;
        return [_text isEqualToString:item.text];
    }
    return NO;
}

- (void)setDetailsArray:(NSMutableArray<NSDictionary *> *)detailsArray
{
    _detailsArray = [detailsArray mutableCopy];
}

@end
