//
//  OAMultiselectableHeaderView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMultiselectableHeaderView.h"

@implementation OAMultiselectableHeaderView
{
    BOOL _editing;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _checkmarkIndent = 8.0;
        
        //self.backgroundColor = [UIColor redColor];
        _checkmark = [UIButton buttonWithType:UIButtonTypeCustom];
        _checkmark.frame = CGRectMake(0.0, 12.0 + (frame.size.height - 10.0) / 2.0 - 15.0, 30.0, 30.0);
        [_checkmark setImage:[UIImage imageNamed:@"selection_unchecked"] forState:UIControlStateNormal];
        [_checkmark setImage:[UIImage imageNamed:@"selection_checked"] forState:UIControlStateSelected];
        [_checkmark addTarget:self action:@selector(checkPress:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.checkmark];
        _title = [[UILabel alloc] initWithFrame:CGRectMake(45.0, 12.0, frame.size.width - 50.0, frame.size.height - 10.0)];
        _title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _title.font = [UIFont fontWithName:@"AvenirNext-Medium" size:13];
        _title.textColor = [UIColor colorWithRed:0.427f green:0.427f blue:0.447f alpha:1.00f]; //6D6D72
        [self addSubview:self.title];
        
        _editable = YES;
        
        [self doUpdateLayout];
    }
    return self;
}

- (void)setTitleText:(NSString *)title
{
    _title.text = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
}

-(void)checkPress:(id)sender
{
    _checkmark.selected = !_checkmark.selected;
    _selected = _checkmark.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(headerCheckboxChanged:value:)])
        [self.delegate headerCheckboxChanged:self value:_checkmark.selected];
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
        _checkmark.selected = _selected;
    
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
    _checkmark.selected = selected;
}

- (void)doUpdateLayout
{
    if (_editing)
    {
        _checkmark.alpha = 1.0;
        CGRect f = _checkmark.frame;
        f.origin.x = _checkmarkIndent;
        _checkmark.frame = f;
        
        f = _title.frame;
        f.origin.x = 51.0;
        f.size.width = self.bounds.size.width - f.origin.x - 5.0;
        _title.frame = f;
    }
    else
    {
        _checkmark.alpha = 0.0;
        CGRect f = _checkmark.frame;
        f.origin.x = -_checkmark.bounds.size.width;
        _checkmark.frame = f;
        
        f = _title.frame;
        f.origin.x = 13.0;
        f.size.width = self.bounds.size.width - f.origin.x - 5.0;
        _title.frame = f;
    }
}


@end
