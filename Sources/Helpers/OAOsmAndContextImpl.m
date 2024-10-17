//
//  OAOsmAndContextImpl.m
//  OsmAnd Maps
//
//  Created by Alexey K on 10.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAOsmAndContextImpl.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OANameStringMatcher.h"

static NSString * const kGpxRecDir = @"rec";
static NSString * const kGpxImportDir = @"import";

// NOTE: Test implementation
@interface ContextSettingsManager : NSObject <OASSettingsAPI>

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *preferences;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<id<OASKStateChangedListener>> *> *listeners;

@end

@implementation ContextSettingsManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _preferences = [NSMutableDictionary dictionary];
        _listeners = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addPreferenceListenerName:(NSString *)name listener:(id<OASKStateChangedListener>)listener {
    if (!self.listeners[name]) {
        self.listeners[name] = [NSMutableArray array];
    }
    [self.listeners[name] addObject:listener];
}

- (NSString *)getStringPreferenceName:(NSString *)name defValue:(NSString *)defValue global:(BOOL)global shared:(BOOL)shared {
    return self.preferences[name] ?: defValue;
}

- (void)registerPreferenceName:(NSString *)name defValue:(NSString *)defValue global:(BOOL)global shared:(BOOL)shared {
    if (!self.preferences[name]) {
        self.preferences[name] = defValue;
    }
}

- (void)setStringPreferenceName:(NSString *)name value:(NSString *)value {
    self.preferences[name] = value;
    
    NSArray<id<OASKStateChangedListener>> *listenersForKey = self.listeners[name];
    for (id<OASKStateChangedListener> listener in listenersForKey) {
      //  [listener onStateChanged:name newValue:value];
    }
}

@end


@implementation OANameStringMatcherImpl
{
    OANameStringMatcher *_matcher;
}

- (instancetype)initWithName:(NSString *)name mode:(OASKStringMatcherMode *)mode
{
    self = [super init];
    if (self)
    {
        _matcher = [[OANameStringMatcher alloc] initWithNamePart:name mode:[self getMode:mode]];
    }
    return self;
}

- (StringMatcherMode)getMode:(OASKStringMatcherMode *)mode
{
    if (mode == OASKStringMatcherMode.checkOnlyStartsWith)
        return CHECK_ONLY_STARTS_WITH;
    else if (mode == OASKStringMatcherMode.checkStartsFromSpace)
        return CHECK_STARTS_FROM_SPACE;
    else if (mode == OASKStringMatcherMode.checkStartsFromSpaceNotBeginning)
        return CHECK_STARTS_FROM_SPACE_NOT_BEGINNING;
    else if (mode == OASKStringMatcherMode.checkEqualsFromSpace)
        return CHECK_EQUALS_FROM_SPACE;
    else if (mode == OASKStringMatcherMode.checkContains)
        return CHECK_CONTAINS;
    else if (mode == OASKStringMatcherMode.checkEquals)
        return CHECK_EQUALS;
    else
        return CHECK_CONTAINS;
}

- (BOOL)matchesName:(NSString *)name
{
    return [_matcher matches:name];
}

@end

@implementation OAOsmAndContextImpl

- (OASKFile *)getAppDir __attribute__((swift_name("getAppDir()")))
{
    return [[OASKFile alloc] initWithFilePath:OsmAndApp.instance.documentsPath];
}

- (OASKFile *)getGpxDir __attribute__((swift_name("getGpxDir()")))
{
    return [[OASKFile alloc] initWithFilePath:OsmAndApp.instance.gpxPath];
}

- (OASKFile *)getGpxImportDir __attribute__((swift_name("getGpxImportDir()")))
{
    return [[OASKFile alloc] initWithFilePath:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:kGpxImportDir]];
}

- (OASKFile *)getGpxRecordedDir __attribute__((swift_name("getGpxRecordedDir()")))
{
    return [[OASKFile alloc] initWithFilePath:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:kGpxRecDir]];
}

- (id<OASKStringMatcher>)getNameStringMatcherName:(NSString *)name mode:(OASKStringMatcherMode *)mode __attribute__((swift_name("getNameStringMatcher(name:mode:)")))
{
    return [[OANameStringMatcherImpl alloc] init];
}

- (id<OASSettingsAPI>)getSettings __attribute__((swift_name("getSettings()")))
{
    // TODO: Not implement until settings moved to shared lib
    return [ContextSettingsManager new];
}

- (NSString * _Nullable)getAssetAsStringName:(NSString *)name __attribute__((swift_name("getAssetAsString(name:)")))
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name.stringByDeletingPathExtension ofType:name.pathExtension];
    if (filePath)
    {
        NSError *error;
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        if (fileContents) {
            return fileContents;
        } else {
            NSLog(@"Error reading file %@: %@", filePath, [error localizedDescription]);
        }
    } else {
        NSLog(@"File %@ not found in the bundle", name);
    }
    return nil;
}

- (void)searchNearestCityNameLatLon:(OASKLatLon *)latLon callback:(void (^)(NSString * _Nonnull))callback
{
    // TODO: Not implement until searchNearestCityNameLatLon moved to shared lib
    if (callback) callback(@"");
}

- (OASGpxTrackAnalysis *)getTrackPointsAnalyser
{
    //TODO: Not implement until settings moved to shared lib
    return nil;
}

- (OASSpeedConstants * _Nullable)getSpeedSystem __attribute__((swift_name("getSpeedSystem()")))
{
    EOASpeedConstant speedSystem = OAAppSettings.sharedManager.speedSystem.get;
    switch (speedSystem)
    {
        case KILOMETERS_PER_HOUR: return OASSpeedConstants.kilometersPerHour;
        case MILES_PER_HOUR: return OASSpeedConstants.milesPerHour;
        case METERS_PER_SECOND: return OASSpeedConstants.metersPerSecond;
        case MINUTES_PER_MILE: return OASSpeedConstants.minutesPerMile;
        case MINUTES_PER_KILOMETER: return OASSpeedConstants.minutesPerKilometer;
        case NAUTICALMILES_PER_HOUR: return OASSpeedConstants.nauticalmilesPerHour;

        // FIXME: Not supported?
        case FEET_PER_SECOND: return nil;

        default: return nil;
    }
}

- (OASMetricsConstants * _Nullable)getMetricSystem __attribute__((swift_name("getMetricSystem()")))
{
    EOAMetricsConstant metricSystem = OAAppSettings.sharedManager.metricSystem.get;
    switch (metricSystem)
    {
        case KILOMETERS_AND_METERS: return OASMetricsConstants.kilometersAndMeters;
        case MILES_AND_FEET: return OASMetricsConstants.milesAndFeet;
        case MILES_AND_YARDS: return OASMetricsConstants.milesAndYards;
        case MILES_AND_METERS: return OASMetricsConstants.milesAndMeters;
        case NAUTICAL_MILES_AND_METERS: return OASMetricsConstants.nauticalMilesAndMeters;
        case NAUTICAL_MILES_AND_FEET: return OASMetricsConstants.nauticalMilesAndFeet;

        default: return nil;
    }
}

- (BOOL)isGpxFileVisiblePath:(NSString *)path __attribute__((swift_name("isGpxFileVisible(path:)")))
{
    NSString *gpxFilePath = [OAUtilities getGpxShortPath:path];
    return [OAAppSettings.sharedManager.mapSettingVisibleGpx.get containsObject:gpxFilePath];
}

- (OASGpxFile * _Nullable)getSelectedFileByPathPath:(nonnull NSString *)path
{
    // FIXME:
    return nil;
}

@end
