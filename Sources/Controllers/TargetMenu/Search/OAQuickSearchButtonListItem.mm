//
//  OAQuickSearchButtonListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchButtonListItem.h"

@implementation OAQuickSearchButtonListItem
{
    BOOL _actionButton;
}

- (instancetype)initWithIcon:(UIImage *)icon text:(NSString *)text onClickFunction:(OACustomSearchButtonOnClick)onClickFunction
{
    return [self initWithIcon:icon text:text actionButton:NO onClickFunction:onClickFunction];
}

- (instancetype)initWithIcon:(UIImage *)icon text:(NSString *)text actionButton:(BOOL)actionButton onClickFunction:(OACustomSearchButtonOnClick)onClickFunction
{
    self = [super init];
    if (self)
    {
        _icon = icon;
        _text = text;
        _onClickFunction = onClickFunction;
        _actionButton = actionButton;
    }
    return self;
}

- (instancetype)initWithIcon:(UIImage *)icon attributedText:(NSAttributedString *)attributedText onClickFunction:(OACustomSearchButtonOnClick)onClickFunction
{
    self = [super init];
    if (self)
    {
        _icon = icon;
        _attributedText = attributedText;
        _onClickFunction = onClickFunction;
    }
    return self;
}

- (EOAQuickSearchListItemType) getType
{
    return _actionButton ? ACTION_BUTTON : BUTTON;
}

- (NSString *) getName
{
    return self.text;
}

-(NSAttributedString *)getAttributedName
{
    return self.attributedText;
}

- (void)onClick
{
    self.onClickFunction(self);
}

@end
