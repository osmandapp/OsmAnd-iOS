//
//  OAButtonRightIconCell.m
//  OsmAnd
//
// Created by Skalii Dmitrii on 22.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAButtonRightIconCell.h"

@implementation OAButtonRightIconCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClick:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    [self.button setEnabled:NO];
}

- (void)onClick:(UITapGestureRecognizer *)sender
{
    self.onClickFunction(self);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        self.highlighted = YES;
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self performSelector:@selector(setDefaultHighlighted) withObject:nil afterDelay:0.1];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self performSelector:@selector(setDefaultHighlighted) withObject:nil afterDelay:0.1];
}

- (void)setDefaultHighlighted
{
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        self.highlighted = NO;
    }];
}

@end