//
//  OAMissingMapsResult.mm
//  OsmAnd Maps
//

#import "OAMissingMapsResult.h"

@implementation OAMissingMapsResult
{
    NSMutableArray<NSString *> *_missingMaps;
    NSMutableArray<NSString *> *_mapsToUpdate;
    NSMutableArray<NSString *> *_usedMaps;
}

- (instancetype) initWithPoints:(NSArray<CLLocation *> *)points profile:(NSString *)profile
{
    self = [super init];
    if (self)
    {
        _points = points;
        _profile = profile;
        _missingMaps = [NSMutableArray array];
        _mapsToUpdate = [NSMutableArray array];
        _usedMaps = [NSMutableArray array];
        _state = EOAMissingMapsStateNone;
    }
    return self;
}

- (NSArray<NSString *> *) missingMaps
{
    return _missingMaps;
}

- (NSArray<NSString *> *) mapsToUpdate
{
    return _mapsToUpdate;
}

- (NSArray<NSString *> *) usedMaps
{
    return _usedMaps;
}

- (void) addMissingMap:(NSString *)region
{
    [self.class add:region to:_missingMaps];
}

- (void) addMapToUpdate:(NSString *)region
{
    [self.class add:region to:_mapsToUpdate];
}

- (void) addUsedMap:(NSString *)region
{
    [self.class add:region to:_usedMaps];
}

- (void) setState:(EOAMissingMapsState)state
{
    _state = state;
}

- (BOOL) hasMissingMaps
{
    return _missingMaps.count > 0 || _mapsToUpdate.count > 0;
}

- (NSString *) getErrorMessage
{
    // the sentence java and the C++ core build, down to the maps that are missing winning over the
    // ones that are only out of date, so the routing log reads the same whichever planner ran
    NSString *msg = @"";
    if (_missingMaps.count > 0)
        msg = [NSString stringWithFormat:@"%@ need to be downloaded", [self.class join:_missingMaps]];
    else if (_mapsToUpdate.count > 0)
        msg = [NSString stringWithFormat:@"%@ need to be updated", [self.class join:_mapsToUpdate]];
    return [NSString stringWithFormat:@"To calculate the route maps %@", msg];
}

+ (void) add:(NSString *)region to:(NSMutableArray<NSString *> *)regions
{
    if (![regions containsObject:region])
        [regions addObject:region];
}

+ (NSString *) join:(NSArray<NSString *> *)regions
{
    return [NSString stringWithFormat:@"[%@]", [regions componentsJoinedByString:@", "]];
}

@end
