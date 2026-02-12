//
//  OAPOIViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

// analog in android: AmenityBuilder.java

#import "OAPOIViewController.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIHelper.h"
#import "OAPOILocationType.h"
#import "OACollapsableLabelView.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATransportStopType.h"
#import "OATransportStopRoute.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "Localization.h"
#import "OACollapsableNearestPoiTypeView.h"
#import "OAOsmAndFormatter.h"
#import "OAResourcesUIHelper.h"
#import "OALabel.h"
#import "OAWikiArticleHelper.h"
#import "OANativeUtilities.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OACollapsableLabelView.h"
#import "OARenderedObject.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>

#define WIKI_LINK @".wikipedia.org/w"
#define US_MAPS_RECREATION_AREA @"us_maps_recreation_area"


static const NSInteger WAY_MODULO_REMAINDER = 1;

@interface OAPOIViewController ()

@end

@implementation OAPOIViewController
{
    OAPOIHelper *_poiHelper;
    AmenityUIHelper *_amenityUIHelper;
    AdditionalInfoBundle *_infoBundle;
    std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>> _openingHoursInfo;
}

static const NSArray<NSString *> *kContactUrlTags = @[@"youtube", @"facebook", @"instagram", @"twitter", @"x", @"vk", @"ok", @"webcam", @"telegram", @"linkedin", @"pinterest", @"foursquare", @"xing", @"flickr", @"email", @"mastodon", @"diaspora", @"gnusocial", @"skype"];
static const NSArray<NSString *> *kContactPhoneTags = @[PHONE_TAG, MOBILE_TAG, @"whatsapp", @"viber"];
static const NSArray<NSString *> *kPrefixTags = @[@"start_date"];

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
        [self setup:poi];
    }
    return self;
}

- (void) setup:(OAPOI *)poi
{
    self.poi = poi;
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

    NSDictionary<NSString *, NSString *> *extensions = [poi getAmenityExtensions:NO];
    self.customOnlinePhotosPosition = [extensions.allKeys containsObject:WIKIDATA_TAG];
    _infoBundle = [[AdditionalInfoBundle alloc] initWithAdditionalInfo:extensions];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self applyTopToolbarTargetTitle];
}

- (NSString *) getTypeStr
{
    return [self.poi getSubTypeStr];
}

- (UIColor *) getAdditionalInfoColor
{
    return [OANativeUtilities getOpeningHoursColor:_openingHoursInfo];
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return [OANativeUtilities getOpeningHoursDescr:_openingHoursInfo];
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (id) getTargetObj
{
    return self.poi;
}

- (OAMapObject *) mapObject
{
    return self.poi;
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (BOOL) showNearestPoi
{
    return YES;
}

- (BOOL) showRegionNameOnDownloadButton
{
    return YES;
}

- (NSDictionary *)groupAdditionalInfo:(NSDictionary *)originalDict
              withCurrentLocalization:(NSString *)currentLocalization
{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *localizationsDict = [NSMutableDictionary dictionary];
    
    for (NSString *key in originalDict)
    {
        NSString *convertedKey = [self convertKey:key];
        
        if ([_poiHelper isNameTag:convertedKey])
        {
            [self processNameTagWithKey:key
                              convertedKey:convertedKey
                          originalDict:originalDict
                      localizationsDict:localizationsDict];
        }
        else
        {
            [self processAdditionalTypeWithKey:key
                                    convertedKey:convertedKey
                                originalDict:originalDict
                            localizationsDict:localizationsDict
                                  resultDict:resultDict];
        }
    }
    NSMutableArray *keysToUpdate = [NSMutableArray array];
    for (NSString *baseKey in localizationsDict)
    {
        NSDictionary *localizations = localizationsDict[baseKey];
        if (!localizations[baseKey])
        {
            [keysToUpdate addObject:baseKey];
        }
    }
    
    for (NSString *baseKey in keysToUpdate)
    {
        NSMutableDictionary *localizations = localizationsDict[baseKey];
        localizations[baseKey] = originalDict[baseKey];
        localizationsDict[baseKey] = localizations;
    }
    
    NSMutableDictionary *finalDict = [self finalizeLocalizationDict:localizationsDict
                                                       originalDict:originalDict
                                            withCurrentLocalization:currentLocalization];
    
    [self addRemainingEntriesFrom:resultDict to:finalDict];
    
    return [finalDict copy];
}

- (NSString *)convertKey:(NSString *)key
{
    return [key stringByReplacingOccurrencesOfString:@"_-_" withString:@":"];
}

- (void)processNameTagWithKey:(NSString *)key
                  convertedKey:(NSString *)convertedKey
                  originalDict:(NSDictionary *)originalDict
              localizationsDict:(NSMutableDictionary *)localizationsDict
{
    if ([key containsString:@":"])
    {
        NSArray *components = [convertedKey componentsSeparatedByString:@":"];
        if (components.count == 2)
        {
            NSString *baseKey = components[0];
            NSString *localeKey = [NSString stringWithFormat:@"%@:%@", baseKey, components[1]];
            
            NSMutableDictionary *nameDict = [self dictionaryForKey:@"name" inDict:localizationsDict];
            [nameDict setObject:originalDict[convertedKey] forKey:localeKey];
        }
    }
    else
    {
        NSMutableDictionary *nameDict = [self dictionaryForKey:@"name" inDict:localizationsDict];
        [nameDict setObject:originalDict[key] forKey:convertedKey];
    }
}

- (void)processAdditionalTypeWithKey:(NSString *)key
                          convertedKey:(NSString *)convertedKey
                          originalDict:(NSDictionary *)originalDict
                      localizationsDict:(NSMutableDictionary *)localizationsDict
                            resultDict:(NSMutableDictionary *)resultDict
{
    OAPOIBaseType *poiType = [_poiHelper getAnyPoiAdditionalTypeByKey:convertedKey];
    
    if (poiType.lang && [key containsString:@":"])
    {
        NSArray *components = [key componentsSeparatedByString:@":"];
        if (components.count == 2)
        {
            NSString *baseKey = components[0];
            NSString *localeKey = [NSString stringWithFormat:@"%@:%@", baseKey, components[1]];
            
            NSMutableDictionary *baseDict = [self dictionaryForKey:baseKey inDict:localizationsDict];
            [baseDict setObject:originalDict[key] forKey:localeKey];
        }
    }
    else
    {
        [resultDict setObject:originalDict[key] forKey:key];
    }
}

- (NSMutableDictionary *)dictionaryForKey:(NSString *)key inDict:(NSMutableDictionary *)dict
{
    NSMutableDictionary *subDict = dict[key];
    if (!subDict)
    {
        subDict = [NSMutableDictionary dictionary];
        dict[key] = subDict;
    }
    return subDict;
}

- (NSMutableDictionary *)finalizeLocalizationDict:(NSDictionary *)localizationsDict
                                     originalDict:(NSDictionary *)originalDict
                      withCurrentLocalization:(NSString *)currentLocalization
{
    NSMutableDictionary *finalDict = [NSMutableDictionary dictionary];
    
    for (NSString *baseKey in localizationsDict)
    {
        NSMutableDictionary *entryDict = [NSMutableDictionary dictionary];
        NSDictionary *localizations = localizationsDict[baseKey];
        
        NSString *nameLocalizedKey = [NSString stringWithFormat:@"%@:%@", baseKey, currentLocalization];
        NSString *nameValue = localizations[nameLocalizedKey];
        if (!nameValue)
        {
            nameValue = originalDict[baseKey] ?: [localizations allValues].firstObject;
        }

        entryDict[@"name"] = nameValue;
        entryDict[@"localization"] = localizations;
        [finalDict setObject:[entryDict copy] forKey:baseKey];
    }
    
    return finalDict;
}

- (void)addRemainingEntriesFrom:(NSDictionary *)resultDict to:(NSMutableDictionary *)finalDict {
    for (NSString *key in resultDict)
    {
        if (![finalDict objectForKey:key])
        {
            [finalDict setObject:resultDict[key] forKey:key];
        }
    }
}

- (void) buildInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    [self processRoutePointAmenityTags:rows];
    [self buildInternalRows:rows];
    
    [self buildNearestRowsForAmenity:rows];
    [self buildAltNamesRow:rows];
    [self buildNamesRow:rows];
}

- (void)buildDescription:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    // TODO: implement
//    Map<String, Object> filteredInfo = infoBundle.getFilteredLocalizedInfo();
//    if (!buildShortWikiDescription(view, filteredInfo, true)) {
//        Pair<String, Locale> pair = AmenityUIHelper.getDescriptionWithPreferredLang(app, amenity, DESCRIPTION, filteredInfo);
//        if (pair != null) {
//            buildDescriptionRow(view, pair.first);
//            infoBundle.setCustomHiddenExtensions(Collections.singletonList(DESCRIPTION));
//        }
//    }
    
    if (self.customOnlinePhotosPosition)
        [self buildPhotosRow];
}

- (void)buildInternalRows:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    NSString *lang = [[OAAppSettings.sharedManager settingPrefMapLanguage] get];
    _amenityUIHelper = [[AmenityUIHelper alloc] initWithPreferredLang:lang infoBundle:_infoBundle];
    _amenityUIHelper.latLon = CLLocationCoordinate2DMake(self.poi.latitude, self.poi.longitude);
    _amenityUIHelper.showDefaultTags = false; // amenityUIHelper.setShowDefault(this.showDefaultTags);
    NSArray<OAAmenityInfoRow *> *buildedRows = [_amenityUIHelper buildInternal]; //row
    [rows addObjectsFromArray:buildedRows];
}

- (void)processRoutePointAmenityTags:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    // TODO: implement
}

- (void)buildNearestRowsForAmenity:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    // TODO: implement
}

- (void)buildAltNamesRow:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    if (_amenityUIHelper)
    {
        OAAmenityInfoRow *row = [_amenityUIHelper buildNamesRowWithNamesMap:[self.poi getAltNamesMap] altName:YES];
        if (row)
            [rows addObject:row];
    }
}

- (void)buildNamesRow:(NSMutableArray<OAAmenityInfoRow *> *)rows
{

    if (_amenityUIHelper)
    {
        NSMutableDictionary<NSString *, NSString *> *names = [NSMutableDictionary new];
        NSString *name = [self.poi name];
        if (!NSStringIsEmpty(name))
            names[@""] = name;
        
        
        NSDictionary<NSString *, NSString *> *namesMap = [self.poi getNamesMap:YES];
        [names addEntriesFromDictionary:namesMap];
        
        OAAmenityInfoRow *row = [_amenityUIHelper buildNamesRowWithNamesMap:names altName:NO];
        if (row)
            [rows addObject:row];
    }
}

- (void)configureRowValue:(id)value
                      dic:(NSDictionary *)dic
             convertedKey:(NSString *)convertedKey
                      row:(OAAmenityInfoRow *)row
{
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSMutableArray *array = [NSMutableArray array];
        NSDictionary *val = dic[convertedKey][@"localization"];
        if ([_poiHelper isNameTag:convertedKey])
        {
            row.text = self.poi.name;
            row.textPrefix = OALocalizedString(@"shared_string_name");
        }
        if (val.allKeys.count > 0)
        {
            for (NSString *key in val.allKeys)
            {
                OAPOIBaseType *poi = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
                NSString *formattedKey = [key stringByReplacingOccurrencesOfString:convertedKey withString:@"name"];

                [array addObject:@{
                    @"key": formattedKey,
                    @"value": val[key],
                    @"localizedTitle": poi ? poi.nameLocalized : @""
                }];
            }
            [row setDetailsArray:array];
        }
    }
}

- (void)addRowIfNotExists:(OAAmenityInfoRow *)newRow toDestinationRows:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    if (![rows containsObject:newRow])
        [rows addObject:newRow];
}

- (NSArray<NSString *> *)getFormattedPrefixAndText:(NSString *)key
                                            prefix:(NSString *)prefix
                                             value:(NSString *)value
                                           amenity:(OAPOI *)amenity
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    numberFormatter.maximumFractionDigits = 2;
    numberFormatter.decimalSeparator = @".";

    EOAMetricsConstant metricSystem = [[OAAppSettings sharedManager].metricSystem get];

    NSString *formattedValue = value;
    NSString *formattedPrefix = prefix;
    if ([key isEqualToString:@"width"])
    {
        formattedPrefix = OALocalizedString(@"shared_string_width");
    }
    else if ([key isEqualToString:@"height"])
    {
        formattedPrefix = OALocalizedString(@"shared_string_height");
    }
    else if (([key isEqualToString:@"depth"] || [key isEqualToString:@"seamark_height"]) && [self isNumericValue:value])
    {
        double valueAsDouble = [value doubleValue];
        if (metricSystem == MILES_AND_FEET || metricSystem == NAUTICAL_MILES_AND_FEET)
        {
            valueAsDouble *= FEET_IN_ONE_METER;
            formattedValue = [NSString stringWithFormat:@"%@ %@",
                    [numberFormatter stringFromNumber:@(valueAsDouble)],
                    OALocalizedString(@"foot")];
        }
        else if (metricSystem == MILES_AND_YARDS)
        {
            valueAsDouble *= YARDS_IN_ONE_METER;
            formattedValue = [NSString stringWithFormat:@"%@ %@",
                    [numberFormatter stringFromNumber:@(valueAsDouble)],
                    OALocalizedString(@"yard")];
        }
        else
        {
            formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"m")];
        }
    }
    else if ([key isEqualToString:@"distance"] && [self isNumericValue:value])
    {
        float valueAsFloatInMeters = [value floatValue] * 1000;
        if (metricSystem == KILOMETERS_AND_METERS)
            formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"km")];
        else
            formattedValue = [OAOsmAndFormatter getFormattedDistance:valueAsFloatInMeters];

        formattedPrefix = [self formatPrefix:prefix units:OALocalizedString(@"shared_string_distance")];
    }
    else if ([key isEqualToString:@"capacity"] && [self isNumericValue:value] && ([amenity.subType isEqualToString:@"water_tower"] || [amenity.subType isEqualToString:@"storage_tank"]))
    {
        formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"cubic_m")];
    }
    else if ([key isEqualToString:@"maxweight"] && [self isNumericValue:value])
    {
        formattedValue = [NSString stringWithFormat:@"%@ %@", value, OALocalizedString(@"metric_ton")];
    }
    else if (([key isEqualToString:@"students"] || [key isEqualToString:@"spots"] || [key isEqualToString:@"seats"]) && [self isNumericValue:value])
    {
        formattedPrefix = [self formatPrefix:prefix units:OALocalizedString(@"shared_string_capacity")];
    }
    else if ([key isEqualToString:@"wikipedia"])
    {
        formattedPrefix = OALocalizedString(@"download_wikipedia_maps");
    }
    return @[formattedPrefix, formattedValue];
}

- (NSString *)formatPrefix:(NSString *)prefix units:(NSString *)units
{
    return prefix != nil && prefix.length > 0 ? [NSString stringWithFormat:@"%@, %@", prefix, units] : units;
}

- (NSString *)encodedPoiNameForLink
{
    return [self.poi encodedPoiNameForLink];
}

- (NSString *)encodedPoiTypeForLink
{
    return [self.poi encodedPoiTypeForLink];
}

- (BOOL) isNumericValue:(NSString *)value
{
    return [value rangeOfCharacterFromSet: [ [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"] invertedSet] ].location == NSNotFound;
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

@end
