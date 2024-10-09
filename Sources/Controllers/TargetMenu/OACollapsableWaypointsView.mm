//
//  OACollapsableWaypointsView.m
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableWaypointsView.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAGpxWptItem.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OAGPXDatabase.h"
#import "OASavingTrackHelper.h"
#import "OAButton.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

#define kMaxItemsCount 11
#define kButtonHeight 32.0

typedef NS_ENUM(NSInteger, EOAWaypointsType)
{
    EOAWaypointGPX = 0,
    EOAWaypointFavorite
};

@interface OACollapsableWaypointsView () <OAButtonDelegate>

@end

@implementation OACollapsableWaypointsView
{
    OsmAndAppInstance _app;
    
    NSArray<OAButton *> *_buttons;
    NSInteger _selectedButtonIndex;
    NSArray *_data;
    
    EOAWaypointsType _type;
    
    NSString *_docPath;
    OASWptPt *_currentWpt;
    
    OAFavoriteItem *_favorite;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self buildViews];
}

-(void) setData:(id)data
{
    if ([data isKindOfClass:OAGpxWptItem.class])
    {
        OAGpxWptItem *item = (OAGpxWptItem *) data;
        _docPath = item.docPath;
        _currentWpt = item.point;
        _data = [OARootViewController.instance.mapPanel.mapViewController getPointsOf:_docPath groupName:item.point.category];
        _type = EOAWaypointGPX;
    }
    else if ([data isKindOfClass:OAFavoriteItem.class])
    {
        _favorite = data;
        NSMutableArray *arr = [NSMutableArray new];
        for (OAFavoriteItem *point in [OAFavoritesHelper getFavoriteItems])
        {
            if ([[point getCategory] isEqualToString:[_favorite getCategory]])
                [arr addObject:point];
        }
        _data = [NSArray arrayWithArray:arr];
        _type = EOAWaypointFavorite;
    }
    [self buildViews];
}

- (OAButton *)createButton:(NSString *)title tag:(NSInteger)tag
{
    OAButton *btn = [OAButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
    btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    btn.layer.cornerRadius = 4.0;
    btn.layer.masksToBounds = YES;
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
    btn.tintColor = [UIColor colorNamed:ACColorNameTextColorActive];
    btn.tag = tag;
    [btn setBackgroundImage:[OAUtilities imageWithColor:[UIColor colorNamed:ACColorNameIconColorActive]] forState:UIControlStateHighlighted];
    btn.delegate = self;
    return btn;
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:kMaxItemsCount];
    for (NSInteger i = 0; i < MIN(kMaxItemsCount - 1, _data.count); i++)
    {
        OAButton * btn = nil;
        if (_type == EOAWaypointGPX)
        {
            btn = [self createButton:((OASWptPt *)_data[i]).name tag:i];
        }
        else if (_type == EOAWaypointFavorite)
        {
            btn = [self createButton:[((OAFavoriteItem *)_data[i]) getDisplayName] tag:i];
        }
        if ([_data[i] isEqual:_currentWpt] || [_data[i] isEqual:_favorite])
        {
            btn.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            btn.userInteractionEnabled = NO;
        }
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    
    if (_data.count > kMaxItemsCount - 1)
    {
        OAButton *showMore = [self createButton:OALocalizedString(@"show_more") tag:kMaxItemsCount];
        [self addSubview:showMore];
        [buttons addObject:showMore];
        [showMore addTarget:self action:@selector(onShowMorePressed:) forControlEvents:UIControlEventTouchDown];
    }
    
    _buttons = [NSArray arrayWithArray:buttons];
}

- (void) onShowMorePressed:(id) sender
{
    OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
    if (_type == EOAWaypointGPX)
    {
        OASGpxDataItem *gpx = nil;
        if (_docPath)
        {
            OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
            NSString *gpxFilePath = [OAUtilities getGpxShortPath:_docPath];
            gpx = [gpxDb getNewGPXItem:gpxFilePath];
        }
        else
        {
            // FIXME:
           // gpx = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
        }
        
        if (gpx)
        {
             [mapPanel openTargetViewWithGPX:gpx];
        }
    }
    else if (_type == EOAWaypointFavorite)
    {
        UIViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:YES];
    }
}

- (void) updateButton
{
    
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 10.;
    CGFloat viewHeight = 10.;
    
    int i = 0;
    for (OAButton *btn in _buttons)
    {
        if (i > 0)
        {
            y += kButtonHeight + 10.0;
            viewHeight += 10.0;
        }
        
        btn.frame = CGRectMake(kMarginLeft, y, width - kMarginLeft - kMarginRight, kButtonHeight);
        viewHeight += kButtonHeight;
        i++;
    }
    
    viewHeight += 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return [sender isKindOfClass:UIMenuController.class] && action == @selector(copy:);
}

- (void)copy:(id)sender
{
    if (_buttons.count > _selectedButtonIndex)
    {
        OAButton *button = _buttons[_selectedButtonIndex];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:button.titleLabel.text];
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    if (_buttons.count > tag)
    {
        OAButton *button = _buttons[tag];
        [UIView animateWithDuration:0.3 animations:^{
            button.layer.backgroundColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
            button.layer.borderColor = UIColor.clearColor.CGColor;
            button.tintColor = UIColor.whiteColor;
        }                completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                button.layer.backgroundColor = UIColor.clearColor.CGColor;
                button.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorDefault].CGColor;
                button.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                if (_data.count > tag)
                {
                    OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
                    if (_type == EOAWaypointGPX)
                    {
                        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
                        OASWptPt *point = _data[tag];
                        item.point = point;
                        item.docPath = _docPath;
                        OATargetPoint *targetPoint = [mapPanel.mapViewController.mapLayers.gpxMapLayer getTargetPoint:item];
                        targetPoint.centerMap = YES;
                        [mapPanel showContextMenu:targetPoint];
                    }
                    else if (_type == EOAWaypointFavorite)
                    {
                        OAFavoriteItem *favorite = _data[tag];
                        OATargetPoint *targetPoint = [mapPanel.mapViewController.mapLayers.favoritesLayer getTargetPointCpp:favorite.favorite.get()];
                        targetPoint.centerMap = YES;
                        [mapPanel showContextMenu:targetPoint];
                    }
                }
            }];
        }];
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    _selectedButtonIndex = tag;
    if (_buttons.count > _selectedButtonIndex)
        [OAUtilities showMenuInView:self fromView:_buttons[_selectedButtonIndex]];
}

@end
