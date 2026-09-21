//
//  OAMissingMapsResult.h
//  OsmAnd Maps
//
//  What the missing maps check found, on its way from the check to the required maps screen.
//  The same object either planner produces, so the screen reads one kind of answer.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/** What the check found, from the mildest to the worst; the routing status takes the worst of them. */
typedef NS_ENUM(NSInteger, EOAMissingMapsState)
{
    EOAMissingMapsStateNone = 0,
    EOAMissingMapsStateMixedIntermediates,
    EOAMissingMapsStateMixedAtStartOrEnd,
    EOAMissingMapsStateMissingIntermediates,
    EOAMissingMapsStateMissingAtStartOrEnd
};

/**
 * The maps a route needs: the ones that are not installed, the ones too old to be used with the
 * rest, and the ones it would use. Regions are download names, the way the maps themselves name
 * them; the required maps screen turns them into world regions.
 */
@interface OAMissingMapsResult : NSObject

/** The points the check ran over: the start, then every target. */
@property (nonatomic, readonly) NSArray<CLLocation *> *points;

/** The routing profile the map editions were matched against ("car", "bicycle", ...). */
@property (nonatomic, readonly) NSString *profile;

@property (nonatomic, readonly) NSArray<NSString *> *missingMaps;
@property (nonatomic, readonly) NSArray<NSString *> *mapsToUpdate;
@property (nonatomic, readonly) NSArray<NSString *> *usedMaps;

@property (nonatomic, readonly) EOAMissingMapsState state;

- (instancetype) initWithPoints:(NSArray<CLLocation *> *)points profile:(NSString *)profile;

- (void) addMissingMap:(NSString *)region;
- (void) addMapToUpdate:(NSString *)region;
- (void) addUsedMap:(NSString *)region;
- (void) setState:(EOAMissingMapsState)state;

/** Whether anything has to be downloaded before the route can be calculated. */
- (BOOL) hasMissingMaps;

/** Why the route cannot be calculated, worded as java and the C++ core word it. */
- (NSString *) getErrorMessage;

@end

NS_ASSUME_NONNULL_END
