//
//  OAPOIViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIViewController.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OAPOILocationType.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAPOIMyLocationType.h"
#import "OACollapsableLabelView.h"
#import "OAColors.h"
#import "OATransportStopType.h"
#import "OATransportStopRoute.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "Localization.h"

#include <openingHoursParser.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>

static const NSInteger AMENITY_ID_RIGHT_SHIFT = 1;
static const NSInteger NON_AMENITY_ID_RIGHT_SHIFT = 7;
static const NSInteger WAY_MODULO_REMAINDER = 1;

@interface OAPOIViewController ()

@end

@implementation OAPOIViewController
{
    OAPOIHelper *_poiHelper;
    std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>> _openingHoursInfo;
}

static const NSArray<NSString *> *kContactUrlTags = @[@"youtube", @"facebook", @"instagram", @"twitter", @"vk", @"ok", @"webcam", @"telegram", @"linkedin", @"pinterest", @"foursquare", @"xing", @"flickr", @"email", @"mastodon", @"diaspora", @"gnusocial", @"skype"];
static const NSArray<NSString *> *kContactPhoneTags = @[@"phone", @"mobile", @"whatsapp", @"viber"];

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (id) initWithPOI:(OAPOI *)poi
{
    self = [self init];
    if (self)
    {
        _poi = poi;
        if (poi.hasOpeningHours)
            _openingHoursInfo = OpeningHoursParser::getInfo([poi.openingHours UTF8String]);
        
        if ([poi.type.category.name isEqualToString:@"transportation"])
        {
            BOOL showTransportStops = NO;
            OAPOIFilter *f = [poi.type.category getPoiFilterByName:@"public_transport"];
            if (f)
            {
                for (OAPOIType *t in f.poiTypes)
                {
                    if ([t.name isEqualToString:poi.type.name])
                    {
                        showTransportStops = YES;
                        break;
                    }
                }
            }
            if (showTransportStops)
                [self processTransportStop];
        }
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (NSString *) getTypeStr
{
    OAPOIType *type = self.poi.type;
    NSMutableString *str = [NSMutableString string];
    if ([self.poi.nameLocalized isEqualToString:self.poi.type.nameLocalized])
    {
        /*
         if (type.filter && type.filter.nameLocalized)
         {
         [str appendString:type.filter.nameLocalized];
         }
         else*/ if (type.category && type.category.nameLocalized)
         {
             [str appendString:type.category.nameLocalized];
         }
    }
    else if (type.nameLocalized)
    {
        [str appendString:type.nameLocalized];
    }
    
    if (str.length == 0)
    {
        return [self getCommonTypeStr];
    }
    
    return str;
}

- (UIColor *) getAdditionalInfoColor
{
    if (!_openingHoursInfo.empty())
    {
        bool open = false;
        for (auto info : _openingHoursInfo)
        {
            if (info->opened || info->opened24_7)
            {
                open = true;
                break;
            }
        }
        return open ? UIColorFromRGB(color_ctx_menu_amenity_opened_text) : UIColorFromRGB(color_ctx_menu_amenity_closed_text);
    }
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    if (!_openingHoursInfo.empty())
    {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        UIColor *colorOpen = UIColorFromRGB(color_ctx_menu_amenity_opened_text);
        UIColor *colorClosed = UIColorFromRGB(color_ctx_menu_amenity_closed_text);
        for (auto info : _openingHoursInfo)
        {
            if (str.length > 0)
                [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            
            NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", [NSString stringWithUTF8String:info->getInfo().c_str()]]];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_travel_time"] color:info->opened ? colorOpen : colorClosed];
            
            NSAttributedString *strWithImage = [NSAttributedString attributedStringWithAttachment:attachment];
            [s replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:strWithImage];
            [s addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
            [s addAttribute:NSForegroundColorAttributeName value:info->opened ? colorOpen : colorClosed range:NSMakeRange(0, s.length)];
            [str appendAttributedString:s];
        }
        
        UIFont *font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        [str addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, str.length)];
        
        return str;
    }
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (id) getTargetObj
{
    return self.poi;
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    NSString *prefLang = [OAUtilities preferredLang];
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];
    
    if (self.poi.type
        && ![self.poi.type isKindOfClass:[OAPOILocationType class]]
        && ![self.poi.type isKindOfClass:[OAPOIMyLocationType class]])
    {
        UIImage *icon = [self.poi.type icon];
        [rows addObject:[[OARowInfo alloc] initWithKey:self.poi.type.name icon:icon textPrefix:nil text:[self getTypeStr] textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    
    [self.poi.values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        BOOL skip = NO;
        NSString *iconId = nil;
        UIImage *icon = nil;
        UIColor *textColor = nil;
        NSString *textPrefix = nil;
        BOOL isText = NO;
        BOOL isDescription = NO;
        BOOL needLinks = ![@"population" isEqualToString:key];
        BOOL isPhoneNumber = NO;
        BOOL isUrl = NO;
        int poiTypeOrder = 0;
        NSString *poiTypeKeyName = @"";
        BOOL collapsable = NO;
        BOOL collapsed = YES;
        OACollapsableView *collapsableView = nil;
        
        OAPOIBaseType *pt = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
        if (!pt && value && value.length > 0 && value.length < 50)
            pt = [_poiHelper getAnyPoiAdditionalTypeByKey:[NSString stringWithFormat:@"%@_%@", key, value]];

        OAPOIType *pType = nil;
        if (pt)
        {
            pType = (OAPOIType *) pt;
            poiTypeOrder = pType.order;
            poiTypeKeyName = pType.name;
        }
        
        if ([key hasPrefix:@"wiki_lang"])
        {
            skip = YES;
        }
        else if ([key hasPrefix:@"name:"])
        {
            skip = YES;
        }
        else if ([key hasPrefix:@"image"])
        {
            skip = YES;
        }
        else if ([key hasPrefix:@"wikimedia_commons"])
        {
            skip = YES;
        }
        else if ([key hasPrefix:@"wikidata"])
        {
            skip = YES;
        }
        else if ([key isEqualToString:@"opening_hours"])
        {
            iconId = @"ic_working_time.png";
            
            auto parser = OpeningHoursParser::parseOpenedHours([value UTF8String]);
            bool isOpened = parser->isOpened();
            textColor = isOpened ? UIColorFromRGB(0x2BBE31) : UIColorFromRGB(0xDA3A3A);

            collapsable = YES;
            collapsed = YES;            
            collapsableView = [[OACollapsableLabelView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            ((OACollapsableLabelView *)collapsableView).label.text = value;
        }
        else if ([kContactPhoneTags containsObject:key])
        {
            iconId = @"ic_phone_number.png";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isPhoneNumber = YES;
        }
        else if ([key isEqualToString:@"website"])
        {
            iconId = @"ic_website.png";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isUrl = YES;
        }
        else if ([key isEqualToString:@"wikipedia"])
        {
            iconId = @"ic_website.png";
            textColor = UIColorFromRGB(kHyperlinkColor);
            isUrl = YES;
        }
        else if ([key isEqualToString:@"cuisine"])
        {
            iconId = @"ic_cuisine.png";
            NSMutableString *sb = [NSMutableString string];
            NSArray* arr = [value componentsSeparatedByString: @";"];
            if (arr.count > 0)
            {
                for (NSString *c in arr)
                {
                    if (sb.length > 0) {
                        [sb appendString:@", "];
                    } else {
                        [sb appendString:[_poiHelper getPhraseByName:@"cuisine"]];
                        [sb appendString:@": "];
                    }
                    [sb appendString:[_poiHelper getPhraseByName:[[@"cuisine_" stringByAppendingString:c] lowercaseString]]];
                }
            }
            value = sb;
        }
        else if ([key isEqualToString:@"osmand_change"])
        {
            isText = YES;
            value = OALocalizedString(@"osmand_live_deleted_object");
            iconId = @"ic_description.png";
        }
        else
        {
            if ([key rangeOfString:@"description"].length != 0)
            {
                iconId = @"ic_description.png";
            }
            else
            {
                iconId = @"ic_operator.png";
            }
            if (pType)
            {
                if (pType.filterOnly)
                    return;

                poiTypeOrder = pType.order;
                poiTypeKeyName = pType.name;
                if ([kContactUrlTags containsObject:key])
                {
                    textColor = UIColorFromRGB(kHyperlinkColor);
                    isUrl = YES;
                }
                if (pType.parentType && [pType.parentType isKindOfClass:[OAPOIType class]])
                {
                    icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@_%@_%@.png", ((OAPOIType *) pType.parentType).tag, [pType.tag stringByReplacingOccurrencesOfString:@":" withString:@"_"], pType.value]];
                }
                if (!pType.isText)
                {
                    if (pType.poiAdditionalCategory) {
                        value = [NSString stringWithFormat:@"%@: %@", pType.poiAdditionalCategoryLocalized, pType.nameLocalized];
                    } else {
                        value = pType.nameLocalized;
                    }
                }
                else
                {
                    isText = YES;
                    isDescription = [iconId isEqualToString:@"ic_description.png"];
                    textPrefix = pType.nameLocalized;
                }
                if (!isDescription && !icon)
                {
                    icon = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
                    if (isText && icon)
                    {
                        textPrefix = @"";
                    }
                }
                if (!icon && isText)
                {
                    iconId = @"ic_description.png";
                }
            }
            else
            {
                textPrefix = [OAUtilities capitalizeFirstLetterAndLowercase:key];
            }
        }
        
        if (!skip)
        {
            if (isDescription)
            {
                [descriptions addObject:[[OARowInfo alloc] initWithKey:key icon:[OATargetInfoViewController getIcon:@"ic_description.png"] textPrefix:textPrefix text:value textColor:nil isText:YES needLinks:YES order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
            }
            else
            {
                OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:key icon:(icon ? icon : [OATargetInfoViewController getIcon:iconId]) textPrefix:textPrefix text:value textColor:textColor isText:isText needLinks:needLinks order:poiTypeOrder typeName:poiTypeKeyName isPhoneNumber:isPhoneNumber isUrl:isUrl];
                rowInfo.collapsable = collapsable;
                rowInfo.collapsed = collapsed;
                rowInfo.collapsableView = collapsableView;
                [rows addObject:rowInfo];
            }
        }
    }];
    
    if ([OAPlugin getEnabledPlugin:OAOsmEditingPlugin.class])
    {
        long long objectId = self.poi.obfId;
        if (objectId > 0 && ((objectId % 2 == AMENITY_ID_RIGHT_SHIFT) || (objectId >> NON_AMENITY_ID_RIGHT_SHIFT) < INT_MAX))
        {
            OAPOIType *poiType = self.poi.type;
            BOOL isAmenity = poiType && ![poiType isKindOfClass:[OAPOILocationType class]];
            
            long long entityId = objectId >> (isAmenity ? AMENITY_ID_RIGHT_SHIFT : NON_AMENITY_ID_RIGHT_SHIFT);
            BOOL isWay = objectId % 2 == WAY_MODULO_REMAINDER; // check if mapObject is a way
            NSString *link = isWay ? @"https://www.openstreetmap.org/way/" : @"https://www.openstreetmap.org/node/";
            [rows addObject:[[OARowInfo alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_custom_osm_edits.png"] textPrefix:nil text:[NSString stringWithFormat:@"%@%llu", link, entityId] textColor:UIColorFromRGB(kHyperlinkColor) isText:YES needLinks:NO order:10000 typeName:nil isPhoneNumber:NO isUrl:YES]];
        }
    }
    
    NSString *langSuffix = [NSString stringWithFormat:@":%@", prefLang];
    OARowInfo *descInPrefLang = nil;
    for (OARowInfo *desc in descriptions)
    {
        if (desc.key.length > langSuffix.length
            && [[desc.key substringFromIndex:desc.key.length - langSuffix.length] isEqualToString:langSuffix])
        {
            descInPrefLang = desc;
            break;
        }
    }
    
    [descriptions sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
        {
            return NSOrderedAscending;
        }
        else if (row1.order == row2.order)
        {
            return [row1.typeName localizedCompare:row2.typeName];
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    
    if (descInPrefLang)
    {
        [descriptions removeObject:descInPrefLang];
        [descriptions insertObject:descInPrefLang atIndex:0];
    }
    
    int i = 10000;
    for (OARowInfo *desc in descriptions)
    {
        desc.order = i++;
        [rows addObject:desc];
    }
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

- (void) processTransportStop
{
    NSMutableArray<OATransportStopRoute *> *routes = [NSMutableArray array];

    NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;
    BOOL isSubwayEntrance = [self.poi.type.name isEqualToString:@"subway_entrance"];

    const std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>(new OsmAnd::TransportStopsInAreaSearch::Criteria);
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.poi.latitude, self.poi.longitude));
    auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(isSubwayEntrance ? 400 : 150, point31);
    searchCriteria->bbox31 = bbox31;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    auto tbbox31 = OsmAnd::AreaI(bbox31.top() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.left() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.bottom() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM),
                                 bbox31.right() >> (31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM));
    const auto dataInterface = obfsCollection->obtainDataInterface(&tbbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport));

    const auto search = std::make_shared<const OsmAnd::TransportStopsInAreaSearch>(obfsCollection);
    search->performSearch(*searchCriteria,
                          [self, routes, dataInterface, prefLang, transliterate, isSubwayEntrance]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              const auto transportStop = ((OsmAnd::TransportStopsInAreaSearch::ResultEntry&)resultEntry).transportStop;
                              auto dist = OsmAnd::Utilities::distance(transportStop->location.longitude, transportStop->location.latitude, self.poi.longitude, self.poi.latitude);
                              [self addRoutes:routes dataInterface:dataInterface s:transportStop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance];
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
    
    self.routes = [NSArray arrayWithArray:routes];
}

- (void) addRoutes:(NSMutableArray<OATransportStopRoute *> *)routes dataInterface:(std::shared_ptr<OsmAnd::ObfDataInterface>)dataInterface s:(std::shared_ptr<const OsmAnd::TransportStop>)s lang:(NSString *)lang transliterate:(BOOL)transliterate dist:(int)dist isSubwayEntrance:(BOOL)isSubwayEntrance
{
    QList< std::shared_ptr<const OsmAnd::TransportRoute> > rts;
    auto stringTable = std::make_shared<OsmAnd::ObfSectionInfo::StringTable>();

    if (dataInterface->getTransportRoutes(s, &rts, stringTable.get()))
    {
        for (auto rs : rts)
        {
            if (![self containsRef:routes transportRoute:rs])
            {
                OATransportStopType *t = [OATransportStopType findType:rs->type.toNSString()];
                if (isSubwayEntrance && t.type != TST_SUBWAY && dist > 150)
                    continue;
                
                OATransportStopRoute *r = [[OATransportStopRoute alloc] init];
                r.type = t;
                r.desc = rs->getName(QString::fromNSString(lang), transliterate).toNSString();
                r.route = rs;
                r.stop = s;
                if ([OAUtilities isCoordEqual:self.poi.latitude srcLon:self.poi.longitude destLat:s->location.latitude destLon:s->location.longitude] || (isSubwayEntrance && t.type == TST_SUBWAY))
                    r.refStop = s;
                
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

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    NSMutableArray<OATransportStopRoute *> *res = [NSMutableArray array];
    for (OATransportStopRoute *route in self.routes)
    {
        BOOL isCurrentRouteLocal = route.refStop && route.refStop->getName("", false) == route.stop->getName("", false);
        if (!nearby && isCurrentRouteLocal)
            [res addObject:route];
        else if (nearby && !route.refStop)
            [res addObject:route];
    }
    return res;
}

@end
