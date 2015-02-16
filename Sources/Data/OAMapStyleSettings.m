//
//  OAMapStyleSettings.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapStyleSettings.h"

@implementation OAMapStyleParameter
@end

@interface OAMapStyleSettings ()

@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSArray *parameters;

@end

@implementation OAMapStyleSettings

- (instancetype)initWithStyleName:(NSString *)mapStyleName
{
    self = [super init];
    if (self) {
        self.mapStyleName = mapStyleName;
        [self buildParameters];
        [self loadParameters];
    }
    return self;
}

-(void) buildParameters
{
    // TODO - Hardcoded. Need to be read from map style xml
    
    NSMutableArray *params = [NSMutableArray array];
    
    OAMapStyleParameter *param = [[OAMapStyleParameter alloc] init];

    
    
    // Details
    // <renderingProperty attr="moreDetailed" name="More details" description="More details on map" type="boolean" possibleValues="" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"moreDetailed";
    param.title = @"More details on map";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    // <renderingProperty attr="showSurfaces" name="Road surface" description="Show road surfaces" type="boolean" possibleValues="" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"showSurfaces";
    param.title = @"Show road surfaces";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];

    // <renderingProperty attr="showSurfaceGrade" name="Road quality" description="Show road quality" type="boolean" possibleValues="" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"showSurfaceGrade";
    param.title = @"Show road quality";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];

    // <renderingProperty attr="showAccess" name="Show access restrictions" description="Show access restrictions" type="boolean" possibleValues="" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"showAccess";
    param.title = @"Show access restrictions";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];

    // <renderingProperty attr="contourLines" name="Show contour lines" description="Select minimum zoom level to display in map if available. Separate contour file may be needed." type="string" possibleValues="--,16,15,14,13,12,11" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"contourLines";
    param.title = @"Show contour lines";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OAString;
    param.defaultValue = @"--";
    param.possibleValues = @[@"--",@"16",@"15",@"14",@"13",@"12",@"11"];
    [params addObject:param];

    // <renderingProperty attr="coloredBuildings" name="Colored buildings" description="Buildings colored by type" type="boolean" possibleValues="" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"coloredBuildings";
    param.title = @"Buildings colored by type";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];

    // <renderingProperty attr="streetLighting" name="Street lighting" description="Show street lighting" type="boolean" possibleValues="" category="details"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"streetLighting";
    param.title = @"Show street lighting";
    param.category = @"details";
    param.categoryTitle = @"Details";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];

    
    
    
    // --- Routes ---
    // <renderingProperty attr="showCycleRoutes" name="Show cycle routes" description="Show cycle routes (*cn_networks) in bicycle mode" type="boolean" possibleValues="" category="routes"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"showCycleRoutes";
    param.title = @"Show cycle routes";
    param.category = @"routes";
    param.categoryTitle = @"Routes";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    // <renderingProperty attr="osmcTraces" name="Hiking symbol overlay" description="Render symbols of OSMC hiking traces" type="boolean" possibleValues="" category="routes"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"osmcTraces";
    param.title = @"Hiking symbol overlay";
    param.category = @"routes";
    param.categoryTitle = @"Routes";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    // <renderingProperty attr="alpineHiking" name="Alpine hiking view" description="Render paths according to SAC scale" type="boolean" possibleValues="" category="routes"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"alpineHiking";
    param.title = @"Alpine hiking view";
    param.category = @"routes";
    param.categoryTitle = @"Routes";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    // <renderingProperty attr="roadStyle" name="Road style" description="Road style" type="string" possibleValues=",orange,germanRoadAtlas,americanRoadAtlas"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"roadStyle";
    param.title = @"Road style";
    param.category = @"routes";
    param.categoryTitle = @"Routes";
    param.dataType = OAString;
    param.defaultValue = @"";
    param.possibleValues = @[@"",@"orange",@"germanRoadAtlas",@"americanRoadAtlas"];
    [params addObject:param];
    
    
    
    
    // -- Hide ---
    // <renderingProperty attr="noAdminboundaries" name="Hide boundaries" description="Suppress display of admin levels 5-9" type="boolean" possibleValues="" category="hide"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"noAdminboundaries";
    param.title = @"Hide boundaries";
    param.category = @"hide";
    param.categoryTitle = @"Hide";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    // <renderingProperty attr="noPolygons" name="Hide polygons" description="Make all areal land features on map transparent" type="boolean" possibleValues="" category="hide"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"noPolygons";
    param.title = @"Hide polygons";
    param.category = @"hide";
    param.categoryTitle = @"Hide";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    // <renderingProperty attr="hideBuildings" name="Hide buildings" description="Hide buildings" type="boolean" possibleValues="" category="hide"/>
    param.mapStyleName = self.mapStyleName;
    param.name = @"hideBuildings";
    param.title = @"Hide buildings";
    param.category = @"hide";
    param.categoryTitle = @"Hide";
    param.dataType = OABoolean;
    param.defaultValue = @"false";
    param.possibleValues = @[@"true", @"false"];
    [params addObject:param];
    
    self.parameters = params;
    
}

-(NSArray *) getAllParameters
{
    return self.parameters;
}

-(NSArray *) getParameters:(NSString *)category
{
    NSMutableArray *res = [NSMutableArray array];
    for (OAMapStyleParameter *p in self.parameters) {
        if ([p.category isEqualToString:category]) {
            [res addObject:p];
        }
    }
    return res;
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
}

@end
