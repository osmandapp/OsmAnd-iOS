//
//  OACarPlayActiveViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 20.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayActiveViewController.h"
#import "OAColors.h"
#import "OAObservable.h"
#import "OADayNightHelper.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"

@interface OACarPlayActiveViewController ()

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *spacingConstraint;

@end

@implementation OACarPlayActiveViewController
{
    OAAutoObserverProxy *_dayNightModeObserver;
}

- (void)applyAppearance
{
    BOOL nightMode = OADayNightHelper.instance.isNightMode;
    self.view.backgroundColor = nightMode ? UIColorFromRGB(color_carplay_background_night) : UIColorFromRGB(color_carplay_background_day);
    _messageLabel.textColor = nightMode ? UIColor.whiteColor : UIColor.blackColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dayNightModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onDayNightModeChanged)
                                                  andObserve:OsmAndApp.instance.dayNightModeObservable];
    
    _messageLabel.text = self.messageText;
    [self applyAppearance];
    if (self.smallLogo)
    {
        _iconWidthConstraint.constant = 42.;
        _iconHeightConstraint.constant = 42.;
        _spacingConstraint.constant = 15.;
        _messageLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
}

- (void)dealloc
{
    [_dayNightModeObserver detach];
}

- (void) onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyAppearance];
    });
}

@end
