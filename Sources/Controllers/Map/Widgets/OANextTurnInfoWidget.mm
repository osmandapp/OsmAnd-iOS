//
//  OANextTurnInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANextTurnInfoWidget.h"
#import "OsmAndApp.h"
#import "OATurnDrawable.h"

@interface OANextTurnInfoWidget ()

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *leftView;

@end

@implementation OANextTurnInfoWidget
{
    BOOL _horisontalMini;
    
    int _deviatedPath;
    int _nextTurnDistance;
    
    OATurnDrawable *_turnDrawable;
    OsmAndAppInstance _app;
}

- (instancetype) initWithHorisontalMini:(BOOL)horisontalMini
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _horisontalMini = horisontalMini;
        _turnDrawable = [[OATurnDrawable alloc] initWithMini:horisontalMini];
        if (horisontalMini)
        {
            [self setTurnDrawable:_turnDrawable gone:NO];
            [self setTopTurnDrawable:nil];
        }
        else
        {
            [self setTurnDrawable:nil gone:YES];
            [self setTopTurnDrawable:_turnDrawable];
        }
    }
    return self;
}

- (void) setTurnDrawable:(OATurnDrawable *)turnDrawable gone:(BOOL)gone
{
    if (turnDrawable)
    {
        [self setSubview:self.leftView subview:turnDrawable];
        self.leftView.hidden = NO;
        [self setImageHidden:NO];
    }
    else
    {
        self.leftView.hidden = gone;
        [self setImageHidden:gone];
    }
}

- (void) setTopTurnDrawable:(OATurnDrawable *)turnDrawable
{
    if (turnDrawable)
    {
        [self setSubview:self.topView subview:turnDrawable];
        self.topView.hidden = NO;
    }
    else
    {
        self.topView.hidden = YES;
    }
}

- (void) setSubview:(UIView *)view subview:(UIView *)subview
{
    for (UIView *v in view.subviews)
        [v removeFromSuperview];
    
    [view addSubview:subview];
}

@end
