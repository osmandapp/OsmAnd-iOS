//
//  OAQuickSearchButtonListItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchButtonListItem.h"

@implementation OAQuickSearchButtonListItem

- (instancetype)initWithIcon:(UIImage *)icon text:(NSString *)text onClickFunction:(OACustomSearchButtonOnClick)onClickFunction
{
    self = [super init];
    if (self)
    {
        _icon = icon;
        _text = text;
        _onClickFunction = onClickFunction;
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
    return BUTTON;
}

- (NSString *) getName
{
    return self.text;
}

-(NSAttributedString *)getAttributedName
{
    return self.attributedText;
}

@end
