//
//  OATargetMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"

#import "OAFavoriteItem.h"
#import "OAFavoriteViewController.h"
#import "OATargetDestinationViewController.h"
#import "OATargetHistoryItemViewController.h"
#import "OAParkingViewController.h"
#import "OAPOIViewController.h"
#import "OAWikiMenuViewController.h"
#import "OAGPXItemViewController.h"
#import "OAGPXEditItemViewController.h"
#import "OAGPXEditWptViewController.h"
#import "OAGPXWptViewController.h"
#import "OARouteTargetViewController.h"
#import "OARouteTargetSelectionViewController.h"
#import "OAImpassableRoadViewController.h"
#import "OAImpassableRoadSelectionViewController.h"
#import "OAGPXRouteViewController.h"
#import "OAMyLocationViewController.h"
#import "OATransportStopViewController.h"
#import "OATransportStopRoute.h"
#import "OATransportRouteController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OATargetMenuViewControllerState

@end

@implementation OATargetMenuControlButton

@end

@interface OATargetMenuViewController ()

@end

@implementation OATargetMenuViewController

+ (OATargetMenuViewController *) createMenuController:(OATargetPoint *)targetPoint activeTargetType:(OATargetPointType)activeTargetType activeViewControllerState:(OATargetMenuViewControllerState *)activeViewControllerState
{
    double lat = targetPoint.location.latitude;
    double lon = targetPoint.location.longitude;
    OATargetMenuViewController *controller = nil;
    switch (targetPoint.type)
    {
        case OATargetFavorite:
        {
            OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
            for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
                double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
                
                if ([OAUtilities isCoordEqual:lat srcLon:lon destLat:favLat destLon:favLon])
                {
                    item.favorite = favLoc;
                    break;
                }
            }
            
            if (item.favorite)
                controller = [[OAFavoriteViewController alloc] initWithItem:item];
            
            break;
        }
            
        case OATargetDestination:
        {
            controller = [[OATargetDestinationViewController alloc] initWithDestination:targetPoint.targetObj];
            break;
        }
            
        case OATargetHistoryItem:
        {
            controller = [[OATargetHistoryItemViewController alloc] initWithHistoryItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetParking:
        {
            if (targetPoint.targetObj)
                controller = [[OAParkingViewController alloc] initWithParking:targetPoint.targetObj];
            else
                controller = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon)];
            break;
        }
            
        case OATargetMyLocation:
        {
            controller = [[OAMyLocationViewController alloc] init];
            break;
        }
            
        case OATargetPOI:
        {
            controller = [[OAPOIViewController alloc] initWithPOI:targetPoint.targetObj];
            break;
        }

        case OATargetTransportStop:
        {
            controller = [[OATransportStopViewController alloc] initWithTransportStop:targetPoint.targetObj];
            break;
        }

        case OATargetTransportRoute:
        {
            controller = [[OATransportRouteController alloc] initWithTransportRoute:targetPoint.targetObj];
            break;
        }

        case OATargetWiki:
        {
            NSString *contentLocale = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            if (!contentLocale)
                contentLocale = [OAUtilities currentLang];
            
            NSString *content = [targetPoint.localizedContent objectForKey:contentLocale];
            if (!content)
            {
                contentLocale = @"";
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            if (!content && targetPoint.localizedContent.count > 0)
            {
                contentLocale = targetPoint.localizedContent.allKeys[0];
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            
            if (content)
                controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:content];
            break;
        }
            
        case OATargetWpt:
        {
            if (activeTargetType == OATargetGPXEdit)
                controller = [[OAGPXEditWptViewController alloc] initWithItem:targetPoint.targetObj];
            else
                controller = [[OAGPXWptViewController alloc] initWithItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetGPX:
        {
            OAGPXItemViewControllerState *state = activeViewControllerState ? (OAGPXItemViewControllerState *)activeViewControllerState : nil;
            
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetGPXEdit:
        {
            OAGPXEditItemViewControllerState *state = activeViewControllerState ? (OAGPXEditItemViewControllerState *)activeViewControllerState : nil;
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetRouteStart:
        case OATargetRouteFinish:
        case OATargetRouteIntermediate:
        {
            controller = [[OARouteTargetViewController alloc] initWithTargetPoint:targetPoint.targetObj];
            break;
        }
            
        case OATargetRouteStartSelection:
        {
            controller = [[OARouteTargetSelectionViewController alloc] initWithTarget:NO intermediate:NO];
            break;
        }
            
        case OATargetRouteFinishSelection:
        {
            controller = [[OARouteTargetSelectionViewController alloc] initWithTarget:YES intermediate:NO];
            break;
        }
            
        case OATargetRouteIntermediateSelection:
        {
            controller = [[OARouteTargetSelectionViewController alloc] initWithTarget:YES intermediate:YES];
            break;
        }
            
        case OATargetImpassableRoad:
        {
            NSNumber *roadId = targetPoint.targetObj;
            controller = [[OAImpassableRoadViewController alloc] initWithRoadId:roadId.unsignedLongLongValue];
            break;
        }
            
        case OATargetImpassableRoadSelection:
        {
            controller = [[OAImpassableRoadSelectionViewController alloc] init];
            break;
        }
            
        case OATargetGPXRoute:
        {
            OAGPXRouteViewControllerState *state = activeViewControllerState ? (OAGPXRouteViewControllerState *)activeViewControllerState : nil;
            OAGpxRouteSegmentType segmentType = (OAGpxRouteSegmentType)targetPoint.segmentIndex;
            if (state)
                controller = [[OAGPXRouteViewController alloc] initWithCtrlState:state];
            else
                controller = [[OAGPXRouteViewController alloc] initWithSegmentType:segmentType];
            
            break;
        }
            
        default:
        {
        }
    }
    return controller;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _topToolbarType = ETopToolbarTypeFixed;
    }
    return self;
}

- (void) setLocation:(CLLocationCoordinate2D)location
{
    _location = location;
    _formattedCoords = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:location];
}

- (UIImage *) getIcon
{
    return nil;
}

- (BOOL) needAddress
{
    return YES;
}

- (NSString *) getTypeStr
{
    return [self getCommonTypeStr];
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"sett_arr_loc");
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSAttributedString *) getAttributedCommonTypeStr
{
    return nil;
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
    NSMutableAttributedString *stringGroup = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", group]];
    NSTextAttachment *groupAttachment = [[NSTextAttachment alloc] init];
    groupAttachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_small_group.png"] color:UIColorFromRGB(0x808080)];
    
    NSAttributedString *groupStringWithImage = [NSAttributedString attributedStringWithAttachment:groupAttachment];
    [stringGroup replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:groupStringWithImage];
    [stringGroup addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
    
    [string appendAttributedString:stringGroup];
    
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
    
    return string;
}

- (UIColor *) getAdditionalInfoColor
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _navBar.hidden = YES;
    _actionButtonPressed = NO;
    
    if ([self hasTopToolbarShadow])
    {
        // drop shadow
        [self.navBar.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.navBar.layer setShadowOpacity:0.3];
        [self.navBar.layer setShadowRadius:3.0];
        [self.navBar.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    }
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) buttonBackPressed:(id)sender
{
    if (self.topToolbarType == ETopToolbarTypeFloating)
    {
        if (self.delegate)
            [self.delegate requestHeaderOnlyMode];
    }

    [self backPressed];
}

- (IBAction) buttonOKPressed:(id)sender
{
    _actionButtonPressed = YES;
    [self okPressed];
}

- (IBAction) buttonCancelPressed:(id)sender
{
    _actionButtonPressed = YES;
    if (self.topToolbarType == ETopToolbarTypeFloating)
    {
        if (self.delegate)
            [self.delegate requestHeaderOnlyMode];
    }
    [self cancelPressed];
}

- (void) backPressed
{
    // override
}

- (void) okPressed
{
    // override
}

- (void) cancelPressed
{
    // override
}

- (BOOL) hasContent
{
    return YES; // override
}

- (CGFloat) contentHeight
{
    return 0.0; // override
}

- (CGFloat) contentHeight:(CGFloat)width
{
    return [self contentHeight];
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    _contentView.backgroundColor = color;
}

- (BOOL) hasInfoView
{
    return [self hasInfoButton] || [self hasRouteButton];
}

- (BOOL) hasInfoButton
{
    return [self hasContent] && ![self isLandscape];
}

- (BOOL) hasRouteButton
{
    return YES;
}

- (BOOL) showTopControls
{
    if (self.delegate)
        return ![self.delegate isInFullMode] && ![self.delegate isInFullScreenMode] && self.topToolbarType != ETopToolbarTypeFixed;
    else
        return NO;
}

- (BOOL) supportMapInteraction
{
    return NO; // override
}

- (BOOL) showNearestWiki;
{
    return NO; // override
}

- (BOOL) supportFullMenu
{
    return YES; // override
}

- (BOOL) supportFullScreen
{
    return YES; // override
}

- (void) goHeaderOnly
{
    // override
}

- (void) goFull
{
    // override
}

- (void) goFullScreen
{
    // override
}

- (BOOL) hasTopToolbar
{
    return NO; // override
}

- (BOOL) shouldShowToolbar
{
    return NO; // override
}

- (BOOL) hasTopToolbarShadow
{
    return YES;
}

- (void) setTopToolbarType:(ETopToolbarType)topToolbarType
{
    _topToolbarType = topToolbarType;
}

- (void) applyTopToolbarTargetTitle
{
    if (self.delegate)
        self.titleView.text = [self.delegate getTargetTitle];
}

- (void) setTopToolbarAlpha:(CGFloat)alpha
{
    if ([self hasTopToolbar])
    {
        switch (self.topToolbarType)
        {
            case ETopToolbarTypeFloating:
            case ETopToolbarTypeMiddleFixed:
                if (self.navBar.alpha != alpha)
                    self.navBar.alpha = alpha;
                break;
                
            case ETopToolbarTypeFixed:
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeFixed alpha:alpha];
                self.navBar.alpha = 1.0;
                break;

            default:
                break;
        }
    }
}

- (void) setMiddleToolbarAlpha:(CGFloat)alpha
{
    if ([self hasTopToolbar])
    {
        CGFloat backButtonAlpha = alpha;
        if (self.topToolbarType != ETopToolbarTypeFloating)
            backButtonAlpha = 0;
        
        if (self.buttonBack.alpha != backButtonAlpha)
            self.buttonBack.alpha = backButtonAlpha;
        
        if (self.topToolbarType == ETopToolbarTypeMiddleFixed)
        {
            if (alpha < 1)
            {
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeMiddleFixed alpha:1.0];
                self.navBar.alpha = alpha;
            }
            else
            {
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeFixed alpha:alpha - 1.0];
                self.navBar.alpha = 1.0;
            }
        }
    }
}

- (void) applyGradient:(BOOL)gradient alpha:(CGFloat)alpha
{
    [self applyGradient:gradient topToolbarType:self.topToolbarType alpha:alpha];
}

- (void) applyGradient:(BOOL)gradient topToolbarType:(ETopToolbarType)topToolbarType alpha:(CGFloat)alpha
{
    if (self.titleGradient && gradient)
    {
        _topToolbarGradient = YES;
        switch (topToolbarType)
        {
            case ETopToolbarTypeFixed:
                self.titleGradient.alpha = 1.0 - alpha;
                self.navBarBackground.alpha = alpha;
                self.titleGradient.hidden = NO;
                self.navBarBackground.hidden = NO;
                break;
                
            case ETopToolbarTypeMiddleFixed:
                self.titleGradient.alpha = alpha;
                self.navBarBackground.alpha = 0;
                self.titleGradient.hidden = NO;
                self.navBarBackground.hidden = YES;
                break;
                
            default:
                break;
        }
    }
    else
    {
        _topToolbarGradient = NO;
        self.titleGradient.alpha = 0.0;
        self.titleGradient.hidden = YES;
        self.navBarBackground.alpha = 1.0;
        self.navBarBackground.hidden = NO;
    }
}

- (BOOL) disablePanWhileEditing
{
    return NO; // override
}

- (BOOL) supportEditing
{
    return NO; // override
}

- (void) activateEditing
{
    // override
}

- (BOOL) commitChangesAndExit
{
    return YES; // override
}

- (BOOL) preHide
{
    return YES; // override
}

- (id) getTargetObj
{
    return nil; // override
}

- (OATargetMenuViewControllerState *)getCurrentState
{
    return nil; // override
}

- (BOOL) isLandscape
{
    return DeviceScreenWidth > 470.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (BOOL) hasControlButtons
{
    return self.leftControlButton || self.rightControlButton;
}

- (void) leftControlButtonPressed;
{
    // override
}

- (void) rightControlButtonPressed;
{
    // override
}

- (void) onMenuSwipedOff
{
    // override
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    return @[];
}

- (NSArray<OATransportStopRoute *> *) getLocalTransportStopRoutes
{
    return [self getSubTransportStopRoutes:false];
}

- (NSArray<OATransportStopRoute *> *) getNearbyTransportStopRoutes
{
    return [self getSubTransportStopRoutes:true];
}

@end
