#import <XCTest/XCTest.h>
#import "OAPOI.h"

@interface OAOpeningHoursCheckDateTest : XCTestCase
@end

@implementation OAOpeningHoursCheckDateTest

- (void)testCheckDateReachesCardAndSavedExtensions
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"24/7", CHECK_DATE_OPENING_HOURS_TAG: @"2025-07-29"}];

    NSDictionary *card = [poi getAmenityExtensions:NO];
    XCTAssertEqualObjects(card[CHECK_DATE_OPENING_HOURS_TAG], @"2025-07-29");
    XCTAssertEqualObjects(card[OPENING_HOURS_TAG], @"24/7");

    NSDictionary *saved = [poi toTagValue:@"amenity_" osmPrefix:@"osm_tag_"];
    XCTAssertEqualObjects(saved[@"osm_tag_check_date_opening_hours"], @"2025-07-29");
    XCTAssertEqualObjects(saved[@"amenity_opening_hours"], @"24/7");

    OAPOI *restored = [OAPOI fromTagValue:saved privatePrefix:@"amenity_" osmPrefix:@"osm_tag_"];
    XCTAssertNotNil(restored);
    XCTAssertEqualObjects([restored getAdditionalInfo:CHECK_DATE_OPENING_HOURS_TAG], @"2025-07-29");
    XCTAssertEqualObjects([restored getAmenityExtensions:NO][CHECK_DATE_OPENING_HOURS_TAG], @"2025-07-29");
}

- (void)testOtherOpeningHoursSuffixesRemainExcluded
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{@"custom_opening_hours": @"Mo-Fr 09:00-18:00", CHECK_DATE_OPENING_HOURS_TAG: @"2025-07"}];

    NSDictionary *card = [poi getAmenityExtensions:NO];
    NSDictionary *saved = [poi toTagValue:@"amenity_" osmPrefix:@"osm_tag_"];
    XCTAssertNil(card[@"custom_opening_hours"]);
    XCTAssertNil(saved[@"osm_tag_custom_opening_hours"]);
    XCTAssertEqualObjects(card[CHECK_DATE_OPENING_HOURS_TAG], @"2025-07");
    XCTAssertEqualObjects(saved[@"osm_tag_check_date_opening_hours"], @"2025-07");
}

- (void)testMissingCheckDateIsNotGenerated
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"24/7"}];
    XCTAssertNil([poi getAmenityExtensions:NO][CHECK_DATE_OPENING_HOURS_TAG]);
    XCTAssertNil([poi toTagValue:@"amenity_" osmPrefix:@"osm_tag_"][@"osm_tag_check_date_opening_hours"]);
}

@end
