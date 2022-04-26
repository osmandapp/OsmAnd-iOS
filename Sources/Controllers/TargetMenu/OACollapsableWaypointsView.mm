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
#import "OAGPXDocument.h"
#import "OAFavoriteItem.h"
#import "OARootViewController.h"
#import "OAMapLayers.h"
#import "OAGPXDatabase.h"
#import "OASavingTrackHelper.h"

#define kMaxItemsCount 11
#define kButtonHeight 32.0

typedef NS_ENUM(NSInteger, EOAWaypointsType)
{
    EOAWaypointGPX = 0,
    EOAWaypointFavorite
};

@interface OACollapsableWaypointsView () <OACustomButtonDelegate>

@end

@implementation OACollapsableWaypointsView
{
    OsmAndAppInstance _app;
    
    NSArray<OACustomButton *> *_buttons;
    NSInteger _selectedButtonIndex;
    NSArray *_data;
    
    EOAWaypointsType _type;
    
    NSString *_docPath;
    OAWptPt *_currentWpt;
    
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

-(void) setData:(id)data
{
    if ([data isKindOfClass:OAGpxWptItem.class])
    {
        OAGpxWptItem *item = (OAGpxWptItem *) data;
        _docPath = item.docPath;
        _currentWpt = item.point;
        _data = [OARootViewController.instance.mapPanel.mapViewController getPointsOf:_docPath];
        _type = EOAWaypointGPX;
    }
    else if ([data isKindOfClass:OAFavoriteItem.class])
    {
        _favorite = data;
        NSMutableArray *arr = [NSMutableArray new];
        for (const auto& fav : _app.favoritesCollection->getFavoriteLocations())
        {
            if (QString::compare(fav->getGroup(), _favorite.favorite->getGroup()) == 0)
            {
                OAFavoriteItem *p = [[OAFavoriteItem alloc] initWithFavorite:fav];
                [arr addObject:p];
            }
        }
        _data = [NSArray arrayWithArray:arr];
        _type = EOAWaypointFavorite;
    }
    [self buildViews];
}

- (OACustomButton *)createButton:(NSString *)title tag:(NSInteger)tag
{
    OACustomButton *btn = [OACustomButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
    btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    btn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    btn.layer.cornerRadius = 4.0;
    btn.layer.masksToBounds = YES;
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    btn.tintColor = UIColorFromRGB(color_primary_purple);
    btn.tag = tag;
    [btn setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(color_coordinates_background)] forState:UIControlStateHighlighted];
    btn.delegate = self;
    return btn;
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:kMaxItemsCount];
    for (NSInteger i = 0; i < MIN(kMaxItemsCount - 1, _data.count); i++)
    {
        OACustomButton * btn = nil;
        if (_type == EOAWaypointGPX)
        {
            btn = [self createButton:((OAWptPt *)_data[i]).name tag:i];
        }
        else if (_type == EOAWaypointFavorite)
        {
            btn = [self createButton:[((OAFavoriteItem *)_data[i]) getDisplayName] tag:i];
        }
        if ([_data[i] isEqual:_currentWpt] || [_data[i] isEqual:_favorite])
        {
            btn.tintColor = UIColorFromRGB(color_tint_gray);
            btn.userInteractionEnabled = NO;
        }
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    
    if (_data.count > kMaxItemsCount - 1)
    {
        OACustomButton *showMore = [self createButton:OALocalizedString(@"shared_string_show_more") tag:kMaxItemsCount];
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
        OAGPX *gpx = nil;
        if (_docPath)
        {
            OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
            NSString *gpxFilePath = [OAUtilities getGpxShortPath:_docPath];
            gpx = [gpxDb getGPXItem:gpxFilePath];
        }
        else
        {
            gpx = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
        }
        
        if (gpx)
            [mapPanel openTargetViewWithGPX:gpx];
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
    for (OACustomButton *btn in _buttons)
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
        OACustomButton *button = _buttons[_selectedButtonIndex];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:button.titleLabel.text];
    }
}

- (void)showMenu:(NSInteger)index
{
    _selectedButtonIndex = index;
    if (_buttons.count > _selectedButtonIndex)
    {
        OACustomButton *button = _buttons[_selectedButtonIndex];
        [self becomeFirstResponder];
        UIMenuController *menuController = UIMenuController.sharedMenuController;
        if (@available(iOS 13.0, *))
        {
            [menuController hideMenu];
            [menuController showMenuFromView:button rect:button.bounds];
        }
        else
        {
            [menuController setMenuVisible:NO animated:YES];
            [menuController setTargetRect:button.bounds inView:button];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    if (_buttons.count > tag)
    {
        OACustomButton *button = _buttons[tag];
        [UIView animateWithDuration:0.3 animations:^{
            button.layer.backgroundColor = UIColorFromRGB(color_coordinates_background).CGColor;
            button.layer.borderColor = UIColor.clearColor.CGColor;
            button.tintColor = UIColor.whiteColor;
        }                completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                button.layer.backgroundColor = UIColor.clearColor.CGColor;
                button.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
                button.tintColor = UIColorFromRGB(color_primary_purple);
                if (_data.count > tag)
                {
                    OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
                    if (_type == EOAWaypointGPX)
                    {
                        OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
                        OAWptPt *point = _data[tag];
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
    [self showMenu:tag];
}

@end
