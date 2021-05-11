//
//  OACollapsableWaypointsView.m
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableWaypointsView.h"
#import "Localization.h"
#import "OACommonTypes.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OALocationConvert.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAFavoriteItem.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapLayers.h"
#import "OAGPXLayer.h"
#import "OATargetPoint.h"
#import "OAGPXDatabase.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"

#define kMaxItemsCount 11
#define kButtonHeight 32.0

typedef NS_ENUM(NSInteger, EOAWaypointsType)
{
    EOAWaypointGPX = 0,
    EOAWaypointFavorite
};

@implementation OACollapsableWaypointsView
{
    OsmAndAppInstance _app;
    
    NSArray<UIButton *> *_buttons;
    NSArray *_data;
    
    EOAWaypointsType _type;
    
    NSString *_docPath;
    OAGpxWpt *_currentWpt;
    
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
        _data = [OARootViewController.instance.mapPanel.mapViewController getLocationMarksOf:item.docPath];
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

- (UIButton *)createButton:(NSString *)title tag:(NSInteger)tag
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    
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
    [btn addTarget:self action:@selector(onButtonTouched:) forControlEvents:UIControlEventTouchDown];
    return btn;
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:kMaxItemsCount];
    for (NSInteger i = 0; i < MIN(kMaxItemsCount - 1, _data.count); i++)
    {
        UIButton * btn = nil;
        if (_type == EOAWaypointGPX)
        {
            btn = [self createButton:((OAGpxWpt *)_data[i]).name tag:i];
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
        [btn addTarget:self action:@selector(btnPress:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    
    if (_data.count > kMaxItemsCount - 1)
    {
        UIButton *showMore = [self createButton:OALocalizedString(@"shared_string_show_more") tag:kMaxItemsCount];
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
            [mapPanel openTargetViewWithGPX:gpx pushed:NO];
    }
    else if (_type == EOAWaypointFavorite)
    {
        UIViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:YES];
    }
}

- (void) onButtonTouched:(id) sender
{
    UIButton *btn = sender;
    [UIView animateWithDuration:0.3 animations:^{
        btn.layer.backgroundColor = UIColorFromRGB(color_coordinates_background).CGColor;
        btn.layer.borderColor = UIColor.clearColor.CGColor;
        btn.tintColor = UIColor.whiteColor;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 animations:^{
            btn.layer.backgroundColor = UIColor.clearColor.CGColor;
            btn.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
            btn.tintColor = UIColorFromRGB(color_primary_purple);
        }];
    }];
}

- (void) updateButton
{
    
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 10.;
    CGFloat viewHeight = 10.;
    
    int i = 0;
    for (UIButton *btn in _buttons)
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

- (void) btnPress:(id)sender
{
    UIButton *btn = sender;
    NSInteger index = btn.tag;
    if (index >= 0 && index < _data.count)
    {
        OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
        if (_type == EOAWaypointGPX)
        {
            OAGpxWptItem *item = [[OAGpxWptItem alloc] init];
            OAGpxWpt *point = _data[index];
            item.point = point;
            item.docPath = _docPath;
            
            OATargetPoint *targetPoint = [mapPanel.mapViewController.mapLayers.gpxMapLayer getTargetPoint:item];
            targetPoint.centerMap = YES;
            [mapPanel showContextMenu:targetPoint];
        }
        else if (_type == EOAWaypointFavorite)
        {
            OAFavoriteItem *favorite = _data[index];
            OATargetPoint *targetPoint = [mapPanel.mapViewController.mapLayers.favoritesLayer getTargetPointCpp:favorite.favorite.get()];
            targetPoint.centerMap = YES;
            [mapPanel showContextMenu:targetPoint];
        }
    }
}
- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

@end
