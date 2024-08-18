//
//  OAAverageSpeedComputer.m
//  OsmAnd Maps
//
//  Created by Paul on 16.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAAverageSpeedComputer.h"
#import "OAAppSettings.h"
#import "OALocationServices.h"
#import "OARootViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OAApplicationMode.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static const long ADD_POINT_INTERVAL_MILLIS = 1000;
static const BOOL CALCULATE_UNIFORM_SPEED = true;

static NSArray<NSNumber *> *MEASURED_INTERVALS;
static const long DEFAULT_INTERVAL_MILLIS = 30 * 60 * 1000L;

static long BIGGEST_MEASURED_INTERVAL;

@interface OASegment : NSObject

@property (nonatomic, assign) double distance;
@property (nonatomic, assign) long startTime;
@property (nonatomic, assign) long endTime;
@property (nonatomic, assign) float speed;

- (instancetype)initWithDistance:(double)distance startTime:(long)startTime endTime:(long)endTime;

- (BOOL) isLowSpeed:(float)speedToSkip;

@end

@interface OASegmentsList : NSObject

@property (nonatomic, assign) NSInteger tailIndex;
@property (nonatomic, assign) NSInteger headIndex;

- (NSArray<OASegment *> *)getSegments:(long)fromTimeInclusive;
- (void)removeSegments:(long)toTimeExclusive;
- (void)addSegment:(OASegment *)segment;

@end

@implementation OASegment

- (instancetype)initWithDistance:(double)distance startTime:(long)startTime endTime:(long)endTime
{
    self = [super init];
    if (self) {
        self.distance = distance;
        self.startTime = startTime;
        self.endTime = endTime;
    }
    return self;
}

- (BOOL) isLowSpeed:(float)speedToSkip
{
    return self.speed < speedToSkip;
}

@end

@implementation OASegmentsList
{
    NSMutableArray<OASegment *> *_segments;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSInteger size = (NSInteger) (BIGGEST_MEASURED_INTERVAL / ADD_POINT_INTERVAL_MILLIS) + 1;
        _segments = [NSMutableArray arrayWithCapacity:size];
    }
    return self;
}

- (NSArray<OASegment *> *)getSegments:(long)fromTimeInclusive
{
    NSMutableArray<OASegment *> *filteredSegments = [NSMutableArray array];
    for (NSInteger i = _tailIndex; i != _headIndex; i = [self nextIndex:i])
    {
        OASegment *segment = _segments[i];
        if (segment && segment.startTime >= fromTimeInclusive)
        {
            [filteredSegments addObject:segment];
        }
    }
    return filteredSegments;
}

- (void) removeSegments:(long)toTimeExclusive
{
    for (NSInteger i = _tailIndex; i != _headIndex; i = [self nextIndex:i]) {
        OASegment *segment = _segments[i];
        if (segment && segment.startTime < toTimeExclusive) {
            [self deleteFromTail];
        }
    }
}

- (void) addSegment:(OASegment *)segment
{
    [self cleanUpIfOverflowed];
    _headIndex = [self nextIndex:_headIndex];
    _segments[_headIndex] = segment;
}

- (void) cleanUpIfOverflowed
{
    if ([self nextIndex:_headIndex] == _tailIndex)
        [self deleteFromTail];
}

- (void) deleteFromTail
{
    [_segments removeLastObject];
    _tailIndex = [self nextIndex:_tailIndex];
}

- (NSInteger) nextIndex:(NSInteger)index
{
    return (index + 1) % _segments.count;
}

@end

@implementation OAAverageSpeedComputer
{
    OAAppSettings *_settings;
    OASegmentsList *_segmentsList;
    NSMutableArray<CLLocation *> *_locations;
    OALocationServices *_locationServices;
    
    CLLocation *_previousLocation;
    long _previousTime;
}

+ (void)initialize
{
    NSMutableArray<NSNumber *> *modifiableIntervals = [NSMutableArray array];
    [modifiableIntervals addObject:@(15 * 1000L)];
    [modifiableIntervals addObject:@(30 * 1000L)];
    [modifiableIntervals addObject:@(45 * 1000L)];
    for (int i = 1; i <= 60; i++)
    {
        [modifiableIntervals addObject:@(i * 60 * 1000L)];
    }
    MEASURED_INTERVALS = modifiableIntervals;
    BIGGEST_MEASURED_INTERVAL = MEASURED_INTERVALS.lastObject.longValue;
}

+ (NSArray<NSNumber *> *) MEASURED_INTERVALS
{
    return MEASURED_INTERVALS;
}

+ (long) DEFAULT_INTERVAL_MILLIS
{
    return DEFAULT_INTERVAL_MILLIS;
}

+ (instancetype) sharedInstance
{
    static dispatch_once_t once;
    static OAAverageSpeedComputer* sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _settings = OAAppSettings.sharedManager;
        _segmentsList = [[OASegmentsList alloc] init];
        _locations = [[NSMutableArray alloc] init];
        _locationServices = OsmAndApp.instance.locationServices;
    }
    return self;
}

- (void)updateLocation:(CLLocation *)location
{
    if (location != nil) {
        long time = [[NSDate date] timeIntervalSince1970] * 1000;
        BOOL save = [self isEnabled] && ![_locationServices isInLocationSimulation];
        if (save)
        {
            [self saveLocation:location time:time];
        }
    }
}

- (BOOL)isEnabled
{
    OAMapWidgetRegistry *widgetRegistry = [OAMapWidgetRegistry sharedInstance];
    OAApplicationMode *appMode = _settings.applicationMode.get;
    NSArray<OAMapWidgetInfo *> *widgetInfos = [widgetRegistry getAllWidgets];

    for (OAMapWidgetInfo *widgetInfo in widgetInfos)
    {
        OABaseWidgetView *widget = widgetInfo.widget;
        BOOL usesAverageSpeed = [widget isKindOfClass:[OAAverageSpeedWidget class]] || [widget isKindOfClass:[OAMapMarkerSideWidget class]];
        if (usesAverageSpeed && [widgetInfo isEnabledForAppMode:appMode] && [OAWidgetsAvailabilityHelper isWidgetAvailableWithWidgetId:widgetInfo.key appMode:appMode]) {
            return YES;
        }
    }

    return NO;
}

- (void)saveLocation:(CLLocation *)location time:(long)time
{
    if (CALCULATE_UNIFORM_SPEED) {
        if (location.speed > 0)
        {
            CLLocation *loc = [[CLLocation alloc] initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course courseAccuracy:location.courseAccuracy speed:location.speed speedAccuracy:location.speedAccuracy timestamp:[NSDate dateWithTimeIntervalSince1970:time / 1000]];
            [_locations addObject:loc];
            [self clearExpiredLocations:_locations measuredInterval:BIGGEST_MEASURED_INTERVAL];
        }
    }
    else if (time - _previousTime >= ADD_POINT_INTERVAL_MILLIS)
    {
        if (_previousLocation && _previousTime > 0)
        {
            double distance = [_previousLocation distanceFromLocation:location];
            OASegment *segment = [[OASegment alloc] initWithDistance:distance startTime:_previousTime endTime:time];
            [_segmentsList addSegment:segment];
        }
        _previousLocation = location;
        _previousTime = time;
    }
}

- (void)clearExpiredLocations:(NSMutableArray<CLLocation *> *)locations measuredInterval:(long)measuredInterval
{
    long expirationTime = [[NSDate date] timeIntervalSince1970] * 1000 - measuredInterval;
    NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
    NSUInteger index = 0;
    for (CLLocation *loc in locations) {
        if (loc.timestamp.timeIntervalSince1970 * 1000 < expirationTime)
            [discardedItems addIndex:index];
        index++;
    }
    [locations removeObjectsAtIndexes:discardedItems];
}

- (float)getSpeedToSkipInMetersPerSecond
{
    EOASpeedConstant speedConstant = [_settings.speedSystem get];
    switch (speedConstant)
    {
        case METERS_PER_SECOND:
            return 1;
        case KILOMETERS_PER_HOUR:
        case MINUTES_PER_KILOMETER:
            return 1 / 3.6f;
        case MILES_PER_HOUR:
        case MINUTES_PER_MILE:
            return METERS_IN_ONE_MILE / (3.6f * METERS_IN_KILOMETER);
        case NAUTICALMILES_PER_HOUR:
            return METERS_IN_ONE_NAUTICALMILE / (3.6f * METERS_IN_KILOMETER);
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Unsupported speed system"];
            break;
    }
}

- (float)getAverageSpeed:(long)measuredInterval skipLowSpeed:(BOOL)skipLowSpeed
{
    if (CALCULATE_UNIFORM_SPEED)
        return [self calculateUniformSpeed:measuredInterval skipLowSpeed:skipLowSpeed];
    else
        return [self calculateNonUniformSpeed:measuredInterval skipLowSpeed:skipLowSpeed];
}

- (float)calculateUniformSpeed:(long)measuredInterval skipLowSpeed:(BOOL)skipLowSpeed
{
    NSMutableArray<CLLocation *> *locationsToUse = [_locations mutableCopy];
    [self clearExpiredLocations:locationsToUse measuredInterval:measuredInterval];

    if (locationsToUse.count > 0)
    {
        float totalSpeed = 0;
        float speedToSkip = [self getSpeedToSkipInMetersPerSecond];

        int countedLocations = 0;
        for (CLLocation *location in locationsToUse)
        {
            if (!skipLowSpeed || location.speed >= speedToSkip) {
                totalSpeed += location.speed;
                countedLocations++;
            }
        }
        return (countedLocations != 0) ? (totalSpeed / countedLocations) : NAN;
    }
    return NAN;
}

- (float)calculateNonUniformSpeed:(long)measuredInterval skipLowSpeed:(BOOL)skipLowSpeed
{
    long intervalStart = [[NSDate date] timeIntervalSince1970] * 1000 - measuredInterval;
    NSArray<OASegment *> *segments = [_segmentsList getSegments:intervalStart];

    double totalDistance = 0;
    double totalTimeMillis = 0;

    float speedToSkip = [self getSpeedToSkipInMetersPerSecond];

    for (OASegment *segment in segments)
    {
        if (!skipLowSpeed || ![segment isLowSpeed:speedToSkip])
        {
            totalDistance += segment.distance;
            totalTimeMillis += segment.endTime - segment.startTime;
        }
    }

    return (totalTimeMillis == 0) ? NAN : (float)(totalDistance / totalTimeMillis * 1000);
}

+ (int)getConvertedSpeedToSkip:(EOASpeedConstant)speedSystem
{
    switch (speedSystem) {
        case METERS_PER_SECOND:
        case KILOMETERS_PER_HOUR:
        case MILES_PER_HOUR:
        case NAUTICALMILES_PER_HOUR:
            return 1;
        case MINUTES_PER_KILOMETER:
        case MINUTES_PER_MILE:
            return 60;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Unsupported speed system"];
            break;
    }
}

@end
