//
//  OAMapStyleSettings.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapStyleSettings.h"
#import "OsmAndApp.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/ResolvedMapStyle.h>
#include <OsmAndCore/QKeyValueIterator.h>

@implementation OAMapStyleParameter
@end

@interface OAMapStyleSettings ()

@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSArray *parameters;
@property (nonatomic) NSDictionary *categories;

@end

@implementation OAMapStyleSettings

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self buildParameters];
        [self loadParameters];
    }
    return self;
}

-(instancetype)initWithStyleName:(NSString *)mapStyleName
{
    self = [super init];
    if (self) {
        self.mapStyleName = mapStyleName;
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

        [self buildParameters:self.mapStyleName];
    }
}

-(void) buildParameters:(NSString *)styleName
{
    
    const auto& resolvedMapStyle = [OsmAndApp instance].resourcesManager->mapStylesCollection->getResolvedStyleByName(QString::fromNSString(styleName));
    const auto& parameters = resolvedMapStyle->parameters;
    
    NSMutableDictionary *categories = [NSMutableDictionary dictionary];
    NSMutableArray *params = [NSMutableArray array];

    for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(parameters)))
    {
        const auto& p = entry.value();
        NSString *name = resolvedMapStyle->getStringById(p->nameId).toNSString();
        
        if ([name isEqualToString:@"appMode"] ||
            //[name isEqualToString:@"transportStops"] ||
            //[name isEqualToString:@"publicTransportMode"] ||
            //[name isEqualToString:@"tramTrainRoutes"] ||
            //[name isEqualToString:@"subwayMode"] ||
            [name isEqualToString:@"engine_v1"] ||
            p->category.isEmpty())

            continue;
        
        //NSLog(@"name = %@ title = %@ decs = %@ type = %d", name, p->title.toNSString(), p->description.toNSString(), p->dataType);

        OAMapStyleParameter *param = [[OAMapStyleParameter alloc] init];
        param.mapStyleName = self.mapStyleName;
        param.name = name;
        param.title = p->title.toNSString();
        param.category = p->category.toNSString();
        
        [categories setObject:[param.category capitalizedString] forKey:param.category];
        
        NSMutableSet *values = [NSMutableSet set];
        [values addObject:@""];
        for (const auto& val : p->possibleValues)
            [values addObject:resolvedMapStyle->getStringById(val.asSimple.asUInt).toNSString()];
        
        param.possibleValues = [[values allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [[obj1 lowercaseString] compare:[obj2 lowercaseString]];
        }];
        
        param.dataType = (OAMapStyleValueDataType)p->dataType;
        switch (param.dataType)
        {
            case OABoolean:
                param.defaultValue = @"false";
                break;
                
            default:
                param.defaultValue = @"";
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
        NSString *name = [NSString stringWithFormat:@"%@_%@", p.mapStyleName, p.name];
        if ([defaults objectForKey:name]) {
            p.value = [defaults valueForKey:name];
        } else {
            p.value = p.defaultValue;
        }
    }
}

-(void) saveParameters
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (OAMapStyleParameter *p in self.parameters) {
        NSString *name = [NSString stringWithFormat:@"%@_%@", p.mapStyleName, p.name];
        [defaults setValue:p.value forKey:name];
    }
    [defaults synchronize];
}

-(void) save:(OAMapStyleParameter *)parameter
{
    NSString *name = [NSString stringWithFormat:@"%@_%@", parameter.mapStyleName, parameter.name];
    [[NSUserDefaults standardUserDefaults] setValue:parameter.value forKey:name];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

@end
