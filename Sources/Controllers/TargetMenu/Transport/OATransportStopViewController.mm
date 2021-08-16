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
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAPOIViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>

@interface OATransportStopViewController ()

@end

@implementation OATransportStopViewController
{
    OATransportStopType *_stopType;
}

- (instancetype) initWithTransportStop:(OATransportStop *)transportStop;
{
    self = [super init];
    if (self)
    {
        _transportStop = transportStop;
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
    if (!_stopType)
        return [OATargetInfoViewController getIcon:@"mx_public_transport.png"];
    else
    {
        NSString *resId = _stopType.topResId;
        if (resId.length > 0)
            return [OATargetInfoViewController getIcon:[resId stringByAppendingString:@".png"]];
        else
            return [OATargetInfoViewController getIcon:@"mx_public_transport.png"];
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

- (void) processTransportStop
{
    NSMutableArray<OATransportStopRoute *> *routes = [NSMutableArray array];
    
    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    auto transportStop = _transportStop.stop;
    
    const std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>(new OsmAnd::TransportStopsInAreaSearch::Criteria);
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(transportStop->location);
    auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(kShowStopsRadiusMeters, point31);
    searchCriteria->bbox31 = bbox31;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    auto tbbox31 = OsmAnd::AreaI(bbox31.top() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.left() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.bottom() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.right() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM));
    const auto dataInterface = obfsCollection->obtainDataInterface(&tbbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport));
    if (dataInterface->transportStopBelongsTo(transportStop))
    {
        BOOL empty = !transportStop->referencesToRoutes.isEmpty();
        if (!empty)
            [self addRoutes:routes dataInterface:dataInterface s:transportStop lang:prefLang transliterate:transliterate dist:0];

        const auto search = std::make_shared<const OsmAnd::TransportStopsInAreaSearch>(obfsCollection);
        search->performSearch(*searchCriteria,
                              [self, routes, dataInterface, prefLang, transliterate, empty]
                              (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                              {
                                  const auto transportStop = ((OsmAnd::TransportStopsInAreaSearch::ResultEntry&)resultEntry).transportStop;
                                  if (transportStop->id != _transportStop.stop->id || empty)
                                  {
                                      auto dist = OsmAnd::Utilities::distance(transportStop->location.longitude, transportStop->location.latitude, _transportStop.location.longitude, _transportStop.location.latitude);
                                      [self addRoutes:routes dataInterface:dataInterface s:transportStop lang:prefLang transliterate:transliterate dist:dist];
                                  }
                              });
        
        [routes sortUsingComparator:^NSComparisonResult(OATransportStopRoute* _Nonnull o1, OATransportStopRoute* _Nonnull o2) {
            if (o1.distance != o2.distance)
                return [OAUtilities compareInt:o1.distance y:o2.distance];
            
            int i1 = [OAUtilities extractFirstIntegerNumber:o1.desc];
            int i2 = [OAUtilities extractFirstIntegerNumber:o2.desc];
            if (i1 != i2)
                return [OAUtilities compareInt:i1 y:i2];
            
            return [o1.desc compare:o2.desc];
        }];
    }
    self.routes = [NSArray arrayWithArray:routes];
}

- (void) addRoutes:(NSMutableArray<OATransportStopRoute *> *)routes dataInterface:(std::shared_ptr<OsmAnd::ObfDataInterface>)dataInterface s:(std::shared_ptr<const OsmAnd::TransportStop>)s lang:(NSString *)lang transliterate:(BOOL)transliterate dist:(int)dist
{
    QList< std::shared_ptr<const OsmAnd::TransportRoute> > rts;
    auto stringTable = std::make_shared<OsmAnd::ObfSectionInfo::StringTable>();
    
    if (dataInterface->getTransportRoutes(s, &rts, stringTable.get()))
    {
        for (auto rs : rts)
        {
            OATransportStopType *type = [OATransportStopType findType:rs->type.toNSString()];
            if (!_stopType && type && [OATransportStopType isTopType:type.type])
                _stopType = type;
            
            if (![self containsRef:routes transportRoute:rs])
            {
                OATransportStopRoute *r = [[OATransportStopRoute alloc] init];
                r.type = type;
                r.desc = rs->getName(QString::fromNSString(lang), transliterate).toNSString();
                r.route = rs;
                r.refStop = _transportStop.stop;
                r.stop = s;
                r.distance = dist;
                [routes addObject:r];
            }
        }
    }
}

- (BOOL) containsRef:(NSArray<OATransportStopRoute *> *)routes transportRoute:(std::shared_ptr<const OsmAnd::TransportRoute>)transportRoute
{
    for (OATransportStopRoute *route in routes)
        if (route.route->ref == transportRoute->ref)
            return YES;

    return NO;
}


- (BOOL) containsRef:(std::shared_ptr<const OsmAnd::TransportRoute>)transportRoute
{
    for (OATransportStopRoute *route in self.routes)
        if (route.route->ref == transportRoute->ref)
            return YES;
    
    return NO;
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
        UIFont *font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightMedium];
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
        int charPos = [ref lastIndexOf:@":"];
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
