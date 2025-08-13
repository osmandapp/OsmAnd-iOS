//
//  OATransportStopViewController.m
//  OsmAnd
//
//  Created by Alexey on 13/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportStopViewController.h"
#import "OATransportStop.h"
#import "OATransportStopRoute.h"
#import "OATransportStopType.h"
#import "OAUtilities.h"
#import "OAPOI.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAPOIViewController.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>

@interface OATransportStopViewController ()

@end

@implementation OATransportStopViewController

- (instancetype) initWithTransportStop:(OATransportStop *)transportStop;
{
    self = [super init];
    if (self)
    {
        self.transportStop = transportStop;
        self.poi = self.transportStop.poi;
        [self processTransportStop];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (UIImage *) getIcon
{
    if (!self.stopType)
        return [OATargetInfoViewController getIcon:@"mx_public_transport"];
    else
    {
        NSString *resId = self.stopType.topResId;
        if (resId.length > 0)
            return [OATargetInfoViewController getIcon:resId];
        else
            return [OATargetInfoViewController getIcon:@"mx_public_transport"];
    }
}

- (NSString *) getTypeStr;
{
    return OALocalizedString(@"transport_stop");
}

- (id) getTargetObj
{
    return self.transportStop;
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloating;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    OAPOI *poi = self.transportStop.poi;
    if (poi)
    {
        OAPOIViewController *poiController = [[OAPOIViewController alloc] initWithPOI:poi];
        [poiController buildRows:rows];
    }
}

+ (UIImage *) createStopPlate:(NSString *)text color:(UIColor *)color
{
    @autoreleasepool
    {
        CGFloat scale = [[UIScreen mainScreen] scale];
        NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        attributes[NSForegroundColorAttributeName] = UIColor.whiteColor;
        UIFont *font = [UIFont scaledSystemFontOfSize:10.0 weight:UIFontWeightMedium];
        attributes[NSFontAttributeName] = font;
        
        CGSize textSize = [text sizeWithAttributes:attributes];
        CGSize size = CGSizeMake(MAX(kTransportStopPlateWidth, textSize.width + 4.0), kTransportStopPlateHeight);
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();

        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:1.0 * scale];
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextAddPath(context, path.CGPath);
        CGContextDrawPath(context, kCGPathFill);

        
        CGRect textRect = CGRectMake(0, (rect.size.height - textSize.height) / 2, rect.size.width, textSize.height);
        [[text uppercaseString] drawInRect:textRect withAttributes:attributes];
        
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }
}

+ (NSString *) adjustRouteRef:(NSString *)ref
{
    if (ref)
    {
        NSInteger charPos = [ref lastIndexOf:@":"];
        if (charPos != -1)
            ref = [ref substringToIndex:charPos];
        
        if (ref.length > 4)
        {
            ref = [ref substringToIndex:4];
            ref = [ref stringByAppendingString:@"…"];
        }
        
    }
    return ref;
}

@end
