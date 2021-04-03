//
//  OAMultiselectableHeaderView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMultiselectableHeaderView.h"
#import "Localization.h"
#import "OAColors.h"

#define kMargin 16.0

static UIFont *_btnFont;

@implementation OAMultiselectableHeaderView
{
    BOOL _editing;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _btnFont = [UIFont systemFontOfSize:13.0];
    
    _selectAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat width = self.frame.size.width;
    CGSize textSize = [OAUtilities calculateTextBounds:[OALocalizedString(@"key_hint_deselect") uppercaseStringWithLocale:[NSLocale currentLocale]] width:width font:_btnFont];
    _selectAllBtn.frame = CGRectMake(width - textSize.width - OAUtilities.getLeftMargin - kMargin, 12.0, textSize.width, 30.0);
    [_selectAllBtn setTitle:[OALocalizedString(@"key_hint_select") uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateNormal];
    [_selectAllBtn setTitle:[OALocalizedString(@"key_hint_deselect") uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateSelected];
    [_selectAllBtn setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    [_selectAllBtn.titleLabel setFont:_btnFont];
    [_selectAllBtn addTarget:self action:@selector(checkPress:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.selectAllBtn];
    _title = [[UILabel alloc] initWithFrame:CGRectMake(kMargin + OAUtilities.getLeftMargin, 12.0, self.frame.size.width - textSize.width - kMargin * 2 - OAUtilities.getLeftMargin * 2, self.frame.size.height - 10.0)];
    _title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _title.font = _btnFont;
    _title.textColor = [UIColor colorWithRed:0.427f green:0.427f blue:0.447f alpha:1.00f]; //6D6D72
    [self addSubview:self.title];
    
    _editable = YES;
    
    [self doUpdateLayout];
}

- (void)setTitleText:(NSString *)title
{
    _title.text = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

-(void)checkPress:(id)sender
{
    _selectAllBtn.selected = !_selectAllBtn.selected;
    _selected = _selectAllBtn.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerCheckboxChanged:value:)])
        [self.delegate headerCheckboxChanged:self value:_selectAllBtn.selected];
}

-(void)setEditable:(BOOL)editable
{
    _editable = editable;
    if (!editable)
    {
        _editing = NO;
        [self setSelected:NO];
    }

    [self doUpdateLayout];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (_editing == editing || !self.editable)
        return;
    
    _editing = editing;
    if (!editing)
        [self setSelected:NO];
    else
        _selectAllBtn.selected = _selected;
    
    if (animated)
    {
        [UIView animateWithDuration:.3 animations:^{
            [self doUpdateLayout];
        }];
    }
    else
    {
        [self doUpdateLayout];
    }
    
}

-(void)setSelected:(BOOL)selected
{
    _selected = selected;
    _selectAllBtn.selected = selected;
}

- (void)layoutSubviews
{
    CGFloat leftMargin = OAUtilities.getLeftMargin;
    CGRect f = _title.frame;
    f.origin.x = kMargin + leftMargin;
    f.origin.y = 12.0;
    f.size.height = 30.0;
    f.size.width = self.bounds.size.width - f.origin.x - kMargin - (_selectAllBtn.alpha == 1.0 ? _selectAllBtn.frame.size.width : 0) - leftMargin * 2;
    _title.frame = f;
    
    f = _selectAllBtn.frame;
    f.origin.x = self.frame.size.width - f.size.width - leftMargin - kMargin;
    _selectAllBtn.frame = f;
}

- (void)doUpdateLayout
{
    CGFloat leftMargin = OAUtilities.getLeftMargin;
    if (_editing)
    {
        _selectAllBtn.alpha = 1.0;
        CGRect f = _selectAllBtn.frame;
        f.origin.x = self.frame.size.width - _selectAllBtn.frame.size.width - leftMargin - kMargin;
        _selectAllBtn.frame = f;
        
        f = _title.frame;
        f.size.width = self.bounds.size.width - f.origin.x - kMargin - _selectAllBtn.frame.size.width - leftMargin * 2;
        _title.frame = f;
    }
    else
    {
        _selectAllBtn.alpha = 0.0;
        
        CGRect f = _title.frame;
        f.origin.x = kMargin;
        f.size.width = self.bounds.size.width - f.origin.x - kMargin - leftMargin * 2;
        _title.frame = f;
    }
}


@end
