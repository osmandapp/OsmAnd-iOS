//
//  OASearchByNameFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 24/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASearchByNameFilter.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAPOIHelper.h"
#import "OAMapUtils.h"
#import "OAResultMatcher.h"

static NSString* const FILTER_ID = BY_NAME_FILTER_ID;

@interface OASearchByNameFilter ()

@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSString *filterId;
@property (nonatomic, readwrite) NSArray<NSNumber *> *distanceToSearchValues;
@property (nonatomic, readwrite) NSArray<OAPOI *> *currentSearchResult;

@end

@implementation OASearchByNameFilter

@synthesize name, filterId, distanceToSearchValues, currentSearchResult;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.name = OALocalizedString(@"poi_filter_by_name");
        self.filterId = FILTER_ID;
        self.distanceToSearchValues = @[@100, @1000, @20000];
    }
    return self;
}

-(BOOL)isAutomaticallyIncreaseSearch
{
    return NO;
}

-(NSArray<OAPOI *> *)searchAmenitiesInternal:(double)lat lon:(double)lon topLatitude:(double)topLatitude bottomLatitude:(double)bottomLatitude leftLongitude:(double)leftLongitude rightLongitude:(double)rightLongitude zoom:(int)zoom matcher:(OAResultMatcher<OAPOI *> *)matcher
{
    int limit = self.distanceInd == 0 ? 500 : -1;
    NSArray<OAPOI *> *result;
    if ([self.filterByName trim].length > 0)
    {
        BOOL __block elimit = NO;
        result = [OAPOIHelper findPOIsByName:self.filterByName topLatitude:topLatitude leftLongitude:leftLongitude bottomLatitude:bottomLatitude rightLongitude:rightLongitude matcher:[[OAResultMatcher<OAPOI *> alloc] initWithPublishFunc:^BOOL(OAPOI *__autoreleasing *object) {

            if (limit != -1 && currentSearchResult.count > limit)
                elimit = YES;

            if ([matcher publish:*object])
                return YES;

            return NO;

        } cancelledFunc:^BOOL{
            return [matcher isCancelled] || elimit;
        }]];
        
        result = [OAMapUtils sortPOI:result lat:lat lon:lon];
    }
    currentSearchResult = result;
    return currentSearchResult;
}


@end
