//
//  OAMapStyleSettings.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapStyleSettings.h"
#import "OsmAndApp.h"
#import "OALog.h"
#import "Localization.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/ResolvedMapStyle.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAMapStyleParameter

- (NSString *)getValueTitle
{
    NSString *res;
    
    for (OAMapStyleParameterValue *val in self.possibleValues)
        if ([val.name isEqualToString:self.value])
        {
            return val.title;
        }

    res = self.value;
    
    if (self.dataType != OABoolean && [res isEqualToString:@""] && self.defaultValue.length > 0)
        res = OALocalizedString([NSString stringWithFormat:@"rendering_value_%@_name", self.defaultValue]);
    
    return res;
}

@end

@implementation OAMapStyleParameterValue
@end

@interface OAMapStyleSettings ()

@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSString *mapPresetName;
@property (nonatomic) NSArray *parameters;
@property (nonatomic) NSDictionary *categories;

@end

@interface OAMapStyleSettings ()

@property (nonatomic) OAMapSource* lastMapSource;

@end

@implementation OAMapStyleSettings

+ (OAMapStyleSettings*) sharedInstance
{
    static OAMapStyleSettings *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAMapStyleSettings alloc] init];
    });
    
    if (![[OsmAndApp instance].data.lastMapSource isEqual:_sharedInstance.lastMapSource])
    {
        [_sharedInstance buildParameters];
        [_sharedInstance loadParameters];
    }
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self buildParameters];
        [self loadParameters];
    }
    return self;
}

-(instancetype)initWithStyleName:(NSString *)mapStyleName mapPresetName:(NSString *)mapPresetName
{
    self = [super init];
    if (self) {
        self.mapStyleName = mapStyleName;
        self.mapPresetName = mapPresetName;
        [self buildParameters:mapStyleName];
        [self loadParameters];
    }
    return self;
}

-(void) buildParameters
{
    OsmAndAppInstance _app = [OsmAndApp instance];

    // Determine what type of map-source is being activated
    typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;
    OAMapSource* lastMapSource = _app.data.lastMapSource;
    auto resourceId = QString::fromNSString(lastMapSource.resourceId);
    auto mapSourceResource = _app.resourcesManager->getResource(resourceId);
    if (!mapSourceResource)
    {
        // Missing resource, shift to default
        _app.data.lastMapSource = [OAAppData defaults].lastMapSource;
        resourceId = QString::fromNSString(_app.data.lastMapSource.resourceId);
        mapSourceResource = _app.resourcesManager->getResource(resourceId);
    }

    if (!mapSourceResource)
        return;
    
    if (mapSourceResource->type == OsmAndResourceType::MapStyle)
    {
        const auto& unresolvedMapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(mapSourceResource->metadata)->mapStyle;
        self.mapStyleName = unresolvedMapStyle->name.toNSString();
        self.mapPresetName = _app.data.lastMapSource.variant;

        [self buildParameters:self.mapStyleName];
        
        self.lastMapSource = [lastMapSource copy];
    }
}

-(void) buildParameters:(NSString *)styleName
{
    
    const auto& resolvedMapStyle = [OsmAndApp instance].resourcesManager->mapStylesCollection->getResolvedStyleByName(QString::fromNSString(styleName));
    const auto& parameters = resolvedMapStyle->getParameters();
    
    NSMutableDictionary *categories = [NSMutableDictionary dictionary];
    NSMutableArray *params = [NSMutableArray array];

    for(const auto& p : OsmAnd::constOf(parameters))
    {
        NSString *name = resolvedMapStyle->getStringById(p->getNameId()).toNSString();
        
        //NSLog(@"name = %@ title = %@ decs = %@ category = %@", name, p->getTitle().toNSString(), p->getDescription().toNSString(), p->getCategory().toNSString());

        if ([name isEqualToString:@"appMode"] ||
            [name isEqualToString:@"transportStops"] ||
            //[name isEqualToString:@"publicTransportMode"] ||
            //[name isEqualToString:@"tramTrainRoutes"] ||
            //[name isEqualToString:@"subwayMode"] ||
            //p->getCategory().isEmpty() ||
            [name isEqualToString:@"engine_v1"])

            continue;
        
        NSString *attrLocKey = [NSString stringWithFormat:@"rendering_attr_%@_name", name];
        NSString *attrLocText = OALocalizedString(attrLocKey);
        if ([attrLocKey isEqualToString:attrLocText])
            attrLocText = p->getTitle().toNSString();

        OAMapStyleParameter *param = [[OAMapStyleParameter alloc] init];
        param.mapStyleName = self.mapStyleName;
        param.mapPresetName = self.mapPresetName;
        param.name = name;
        param.title = attrLocText;
        param.category = p->getCategory().toNSString();

        if (param.category.length > 0)
        {
            NSString *categoryLocKey = [NSString stringWithFormat:@"rendering_category_%@", param.category];
            NSString *categoryLocText = OALocalizedString(categoryLocKey);
            if ([categoryLocKey isEqualToString:categoryLocText])
                categoryLocText = [param.category capitalizedString];
            
            [categories setObject:categoryLocText forKey:param.category];
        }
        
        NSMutableSet *values = [NSMutableSet set];
        [values addObject:@""];
        for (const auto& val : p->getPossibleValues())
            [values addObject:resolvedMapStyle->getStringById(val.asSimple.asUInt).toNSString()];
        
        NSMutableArray *valArr = [NSMutableArray array];
        for (NSString *v in [values allObjects])
        {
            OAMapStyleParameterValue *val = [[OAMapStyleParameterValue alloc] init];
            val.name = v;
            
            NSString *valLocKey;
            if (v.length == 0)
                valLocKey = [NSString stringWithFormat:@"rendering_value_%@_name", p->getDefaultValueDescription().toNSString()];
            else
                valLocKey = [NSString stringWithFormat:@"rendering_value_%@_name", v];
            
            NSString *valLocText = OALocalizedString(valLocKey);
            if ([valLocKey isEqualToString:valLocText])
                valLocText = v;
            
            val.title = valLocText;
            [valArr addObject:val];
        }
        
        param.possibleValues = [valArr sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleParameterValue *obj1, OAMapStyleParameterValue *obj2) {
            if (obj1.name.length == 0 && obj2.name.length > 0)
                return NSOrderedAscending;
            if (obj1.name.length > 0 && obj2.name.length == 0)
                return NSOrderedDescending;
            return [[obj1.title lowercaseString] compare:[obj2.title lowercaseString]];
        }];
        
        param.dataType = (OAMapStyleValueDataType)p->getDataType();
        switch (param.dataType)
        {
            case OABoolean:
                param.defaultValue = @"false";
                break;
                
            default:
                param.defaultValue = p->getDefaultValueDescription().toNSString();
                break;
        }

        [params addObject:param];

    }

    self.parameters = params;
    self.categories = categories;
}

-(NSArray *) getAllParameters
{
    return self.parameters;
}

-(OAMapStyleParameter *) getParameter:(NSString *)name
{
    for (OAMapStyleParameter *p in self.parameters) {
        if ([p.name isEqualToString:name])
            return p;
    }
    return nil;
}

-(NSArray *) getAllCategories
{
    return [[self.categories allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [[obj1 lowercaseString] compare:[obj2 lowercaseString]];
    }];
}

-(NSString *) getCategoryTitle:(NSString *)categoryName
{
    return [self.categories valueForKey:categoryName];
}

-(NSArray *) getParameters:(NSString *)category
{
    NSMutableArray *res = [NSMutableArray array];
    for (OAMapStyleParameter *p in self.parameters) {
        if ([p.category isEqualToString:category]) {
            [res addObject:p];
        }
    }
    return [res sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleParameter *obj1, OAMapStyleParameter *obj2) {
        return [[obj1.title lowercaseString] compare:[obj2.title lowercaseString]];
    }];
}

-(void) loadParameters
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (OAMapStyleParameter *p in self.parameters) {
        NSString *name = [NSString stringWithFormat:@"%@_%@_%@", p.mapStyleName, p.mapPresetName, p.name];
        if ([defaults objectForKey:name]) {
            p.value = [defaults valueForKey:name];
        } else {
            p.value = @"";
        }
    }
}

-(void) saveParameters
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (OAMapStyleParameter *p in self.parameters) {
        NSString *name = [NSString stringWithFormat:@"%@_%@_%@", p.mapStyleName, p.mapPresetName, p.name];
        [defaults setValue:p.value forKey:name];
    }
    [defaults synchronize];
}

-(void) save:(OAMapStyleParameter *)parameter
{
    NSString *name = [NSString stringWithFormat:@"%@_%@_%@", parameter.mapStyleName, parameter.mapPresetName, parameter.name];
    [[NSUserDefaults standardUserDefaults] setValue:parameter.value forKey:name];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

+ (OAMapVariantType)getVariantType:(NSString *) variantStr
{
    OAMapVariantType mapVariantType = OAMapVariantDefault;
    if ([variantStr isEqualToString:OAMapVariantCarStr])
        mapVariantType = OAMapVariantCar;
    else if ([variantStr isEqualToString:OAMapVariantPedestrianStr])
        mapVariantType = OAMapVariantPedestrian;
    else if ([variantStr isEqualToString:OAMapVariantBicycleStr])
        mapVariantType = OAMapVariantBicycle;
    
    return mapVariantType;
}

+ (NSString *)getVariantStr:(OAMapVariantType) variantType
{
    NSString *variant;
    if (variantType == OAMapVariantCar)
        variant = OAMapVariantCarStr;
    else if (variantType == OAMapVariantPedestrian)
        variant = OAMapVariantPedestrianStr;
    else if (variantType == OAMapVariantBicycle)
        variant = OAMapVariantBicycleStr;
    else
        variant = OAMapVariantDefaultStr;
    
    return variant;
}

+ (NSString *)getAppModeByVariantType:(OAMapVariantType) variantType
{
    NSString *appMode;
    if (variantType == OAMapVariantCar)
        appMode = OAMapAppModeCar;
    else if (variantType == OAMapVariantPedestrian)
        appMode = OAMapAppModePedestrian;
    else if (variantType == OAMapVariantBicycle)
        appMode = OAMapAppModeBicycle;
    else
        appMode = OAMapAppModeDefault;
    
    return appMode;
}

+ (NSString *)getAppModeByVariantTypeStr:(NSString *) variantStr
{
    NSString *appMode;
    if ([variantStr isEqualToString:OAMapVariantCarStr])
        appMode = OAMapAppModeCar;
    else if ([variantStr isEqualToString:OAMapVariantPedestrianStr])
        appMode = OAMapAppModePedestrian;
    else if ([variantStr isEqualToString:OAMapVariantBicycleStr])
        appMode = OAMapAppModeBicycle;
    else
        appMode = OAMapAppModeDefault;
    
    return appMode;
}

@end
