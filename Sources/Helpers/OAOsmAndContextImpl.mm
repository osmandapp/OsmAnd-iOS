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
#import "OASelectedGpxHelper.h"
#import "OAGPXUIHelper.h"
#import "OAPOI.h"

static NSString * const kGpxRecDir = @"rec";
static NSString * const kGpxImportDir = @"import";

@interface OASettingsAPIImpl : NSObject <OASSettingsAPI>
@end

@implementation OASettingsAPIImpl
{
    NSMutableDictionary<NSString *, id<OASKStateChangedListener>> *_prefListeners;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _prefListeners = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPreferenceSet:) name:kNotificationSetProfileSetting object:nil];
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)onPreferenceSet:(NSNotification *)notification
{
    OACommonPreference *pref = (OACommonPreference *) notification.object;
    id<OASKStateChangedListener> listener = _prefListeners[pref.key];
    if (listener)
        [listener stateChangedChange:[pref getPrefValue]];
}

- (void)registerPreferenceName:(NSString *)name defValue:(NSString *)defValue global:(BOOL)global shared_:(BOOL)shared
{
    OACommonString *pref = [OAAppSettings.sharedManager registerStringPreference:name defValue:defValue];
    if (global)
        [pref makeGlobal];
    if (shared)
        [pref makeShared];
}

- (void)addStringPreferenceListenerName:(nonnull NSString *)name listener:(nonnull id<OASKStateChangedListener>)listener
{
    _prefListeners[name] = listener;
}

- (NSString * _Nullable)getStringPreferenceName:(nonnull NSString *)name
{
    OACommonPreference *pref = [OAAppSettings.sharedManager getPreferenceByKey:name];
    if ([pref isKindOfClass:OACommonString.class])
        return [(OACommonString *)pref get];

    return nil;
}

- (void)setStringPreferenceName:(NSString *)name value:(NSString *)value __attribute__((swift_name("setStringPreference(name:value:)")))
{
    OACommonPreference *pref = [OAAppSettings.sharedManager getPreferenceByKey:name];
    if ([pref isKindOfClass:OACommonString.class])
        [(OACommonString *)pref set:value];
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
{
    id<OASSettingsAPI> _settingsAPI;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _settingsAPI = [[OASettingsAPIImpl alloc] init];
    }
    return self;
}

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
    return [[OANameStringMatcherImpl alloc] initWithName:name mode:mode];
}

- (id<OASSettingsAPI>)getSettings __attribute__((swift_name("getSettings()")))
{
    return _settingsAPI;
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
    // FIXME: crash
    @autoreleasepool {
        OAPOI *nearestCityPOI = [OAGPXUIHelper searchNearestCity:CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude)];
        callback(nearestCityPOI ? nearestCityPOI.name : @"");
    }
}

- (id<OASGpxTrackAnalysisTrackPointsAnalyser> _Nullable)getTrackPointsAnalyser
{
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

- (OASGpxFile *)getSelectedFileByPathPath:(NSString *)path
{
    return [OASelectedGPXHelper.instance getGpxFileFor:path];
}

@end
