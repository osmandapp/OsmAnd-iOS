#import <XCTest/XCTest.h>
#import "OAPOI.h"
#import "OAFavoriteItem.h"
#import "OAFavoriteViewController.h"
#import "OACollapsableLabelView.h"
#import "OALabel.h"
#import "OAUtilities.h"
#import "OAMapPanelViewController.h"
#import "OATargetPointView.h"
#import "OAPOIViewController.h"
#import "OARenderedObject.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAMapPanelViewController (SavedPoiMetadataTests)
@property (nonatomic, strong) OATargetPointView *targetMenuView;
- (OAPOI *)getTargetPointPoi;
@end

@interface OAOpeningHoursCheckDateTest : XCTestCase
@end

@implementation OAOpeningHoursCheckDateTest

- (void)checkResolvedCardMetadataForTargetType:(OATargetPointType)type object:(id)object
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"Mo-Su 08:00-22:00", CHECK_DATE_OPENING_HOURS_TAG: @"2025-03-28", CHECK_DATE_TAG: @"2025-11-18", @"payment_cash_yes": @"yes", @"payment_credit_cards_yes": @"yes", @"payment_debit_cards_yes": @"yes"}];
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    OATargetPointView *menu = [[OATargetPointView alloc] init];
    OATargetPoint *target = [[OATargetPoint alloc] init];
    target.type = type;
    target.targetObj = object;
    menu.targetPoint = target;
    menu.customController = [[OAPOIViewController alloc] initWithPOI:poi];
    panel.targetMenuView = menu;

    OAPOI *resolvedPoi = [panel getTargetPointPoi];
    XCTAssertEqual(resolvedPoi, poi);
    OAFavoriteItem *favorite = [[OAFavoriteItem alloc] initWithLat:50.43599 lon:30.50821 name:@"Resolved POI" category:@""];
    [favorite setAmenity:resolvedPoi];
    OASWptPt *favoritePoint = [favorite toWpt];
    OASWptPt *waypoint = [[OASWptPt alloc] init];
    [waypoint setAmenity:resolvedPoi];
    NSSet *expectedPayments = [NSSet setWithArray:@[@"payment_cash_yes", @"payment_credit_cards_yes", @"payment_debit_cards_yes"]];
    for (OASWptPt *point in @[favoritePoint, waypoint])
    {
        NSDictionary *extensions = [point getExtensionsToRead];
        XCTAssertEqualObjects(extensions[@"amenity_opening_hours"], @"Mo-Su 08:00-22:00");
        XCTAssertEqualObjects(extensions[@"osm_tag_check_date_opening_hours"], @"2025-03-28");
        XCTAssertEqualObjects(extensions[@"osm_tag_check_date"], @"2025-11-18");
        NSSet *payments = [NSSet setWithArray:[extensions[@"collapsable_payment_type"] componentsSeparatedByString:@";"] ?: @[]];
        XCTAssertEqualObjects(payments, expectedPayments);
    }
}

- (void)testRenderedObjectSavesResolvedCardMetadata
{
    [self checkResolvedCardMetadataForTargetType:OATargetRenderedObject object:[[OARenderedObject alloc] init]];
}

- (void)testPoiSavesResolvedCardMetadataInsteadOfOriginalObject
{
    [self checkResolvedCardMetadataForTargetType:OATargetPOI object:[[OAPOI alloc] init]];
}

- (void)testDetailsObjectSavesResolvedCardMetadataInsteadOfOriginalObject
{
    [self checkResolvedCardMetadataForTargetType:OATargetBaseDetailsObject object:[[BaseDetailsObject alloc] init]];
}

- (void)testCoordinateTargetDoesNotSaveSyntheticCardMetadata
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    OATargetPointView *menu = [[OATargetPointView alloc] init];
    OATargetPoint *target = [[OATargetPoint alloc] init];
    target.type = OATargetLocation;
    menu.targetPoint = target;
    menu.customController = [[OAPOIViewController alloc] initWithPOI:[[OAPOI alloc] init]];
    panel.targetMenuView = menu;
    XCTAssertNil([panel getTargetPointPoi]);
}

- (void)testPoiTargetWithoutCardKeepsOriginalMetadata
{
    OAPOI *poi = [[OAPOI alloc] init];
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    OATargetPointView *menu = [[OATargetPointView alloc] init];
    OATargetPoint *target = [[OATargetPoint alloc] init];
    target.type = OATargetPOI;
    target.targetObj = poi;
    menu.targetPoint = target;
    panel.targetMenuView = menu;
    XCTAssertEqual([panel getTargetPointPoi], poi);
}

- (void)testCheckDateReachesCardAndSavedExtensions
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"24/7", CHECK_DATE_OPENING_HOURS_TAG: @"2025-07-29", CHECK_DATE_TAG: @"2025-11-18"}];

    NSDictionary *card = [poi getAmenityExtensions:NO];
    XCTAssertEqualObjects(card[CHECK_DATE_OPENING_HOURS_TAG], @"2025-07-29");
    XCTAssertEqualObjects(card[OPENING_HOURS_TAG], @"24/7");

    NSDictionary *saved = [poi toTagValue:@"amenity_" osmPrefix:@"osm_tag_"];
    XCTAssertEqualObjects(saved[@"osm_tag_check_date_opening_hours"], @"2025-07-29");
    XCTAssertEqualObjects(saved[@"amenity_opening_hours"], @"24/7");

    OAPOI *restored = [OAPOI fromTagValue:saved privatePrefix:@"amenity_" osmPrefix:@"osm_tag_"];
    XCTAssertNotNil(restored);
    XCTAssertEqualObjects([restored getAdditionalInfo:CHECK_DATE_TAG], @"2025-11-18");
    XCTAssertEqualObjects([restored getAdditionalInfo:CHECK_DATE_OPENING_HOURS_TAG], @"2025-07-29");
    XCTAssertEqualObjects([restored getAmenityExtensions:NO][CHECK_DATE_OPENING_HOURS_TAG], @"2025-07-29");
}

- (void)testFavoriteWaypointRoundTripKeepsIndependentCheckDates
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"24/7", CHECK_DATE_OPENING_HOURS_TAG: @"2025-03-28", CHECK_DATE_TAG: @"2025-11-18"}];
    OAFavoriteItem *favorite = [[OAFavoriteItem alloc] initWithLat:50.4359905 lon:30.5082094 name:@"PR5883" category:@""];
    [favorite setAmenity:poi];
    OASWptPt *point = [favorite toWpt];
    XCTAssertEqualObjects([point getExtensionsToRead][@"osm_tag_check_date_opening_hours"], @"2025-03-28");
    OAFavoriteItem *restored = [OAFavoriteItem fromWpt:point category:@""];
    OAPOI *restoredPoi = [restored getAmenity];
    XCTAssertEqualObjects(restoredPoi.openingHours, @"24/7");
    XCTAssertEqualObjects([restoredPoi getAdditionalInfo:CHECK_DATE_OPENING_HOURS_TAG], @"2025-03-28");
    XCTAssertEqualObjects([restoredPoi getAdditionalInfo:CHECK_DATE_TAG], @"2025-11-18");
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

- (void)testRestoredFavoriteCardBuildsOpeningHoursAndCheckDateRows
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"24/7", CHECK_DATE_OPENING_HOURS_TAG: @"2025-03", CHECK_DATE_TAG: @"2025-11"}];
    OAFavoriteItem *favorite = [[OAFavoriteItem alloc] initWithLat:50.4359905 lon:30.5082094 name:@"PR5883" category:@""];
    [favorite setAmenity:poi];
    OAFavoriteItem *restored = [OAFavoriteItem fromWpt:[favorite toWpt] category:@""];
    OAFavoriteViewController *controller = [[OAFavoriteViewController alloc] initWithItem:restored headerOnly:NO];
    NSMutableArray<OAAmenityInfoRow *> *rows = [NSMutableArray array];
    [controller buildInternal:rows];
    OAAmenityInfoRow *hoursRow;
    OAAmenityInfoRow *dateRow;
    for (OAAmenityInfoRow *row in rows)
    {
        if ([row.key isEqualToString:OPENING_HOURS_TAG])
            hoursRow = row;
        if ([row.key isEqualToString:CHECK_DATE_TAG])
            dateRow = row;
        XCTAssertFalse([row.key isEqualToString:CHECK_DATE_OPENING_HOURS_TAG]);
    }
    XCTAssertNotNil(hoursRow);
    XCTAssertEqualObjects(dateRow.text, @"2025-11");
    XCTAssertTrue([hoursRow.collapsableView isKindOfClass:OACollapsableLabelView.class]);
    OACollapsableLabelView *view = (OACollapsableLabelView *)hoursRow.collapsableView;
    XCTAssertTrue([view.label.text hasPrefix:@"24/7\n"]);
    XCTAssertTrue([view.label.text hasSuffix:@"2025-03"]);
}

- (void)testMissingCheckDateIsNotGenerated
{
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{OPENING_HOURS_TAG: @"24/7", CHECK_DATE_TAG: @"2025-11-18"}];
    XCTAssertNil([poi getAmenityExtensions:NO][CHECK_DATE_OPENING_HOURS_TAG]);
    XCTAssertNil([poi toTagValue:@"amenity_" osmPrefix:@"osm_tag_"][@"osm_tag_check_date_opening_hours"]);
}

- (void)testPlainFavoriteDoesNotAcquireSyntheticPoiMetadata
{
    OAFavoriteItem *favorite = [[OAFavoriteItem alloc] initWithLat:52.2 lon:21.0 name:@"Plain favorite" category:@"Regression"];
    [favorite setAddress:@"Test address"];
    [favorite setDescription:@"Personal description"];
    [favorite setIcon:@"special_star"];
    [favorite setExtensions:@{@"hidden": @"true"}];
    [favorite setVisible:YES];
    OASWptPt *point = [favorite toWpt];
    NSDictionary *extensions = [point getExtensionsToRead];
    XCTAssertEqualObjects(point.name, @"Plain favorite");
    XCTAssertEqualObjects(point.desc, @"Personal description");
    XCTAssertEqualObjects(extensions[@"address"], @"Test address");
    XCTAssertNil(extensions[@"hidden"]);
    for (NSString *key in extensions)
    {
        XCTAssertFalse([key hasPrefix:@"amenity_"]);
        XCTAssertFalse([key hasPrefix:@"osm_tag_"]);
        XCTAssertFalse([key hasPrefix:COLLAPSABLE_PREFIX]);
    }
    OAFavoriteViewController *controller = [[OAFavoriteViewController alloc] initWithItem:favorite headerOnly:NO];
    NSMutableArray<OAAmenityInfoRow *> *rows = [NSMutableArray array];
    [controller buildInternal:rows];
    for (OAAmenityInfoRow *row in rows)
        XCTAssertFalse([row.key isEqualToString:CHECK_DATE_TAG] || [row.key isEqualToString:OPENING_HOURS_TAG]);
}

- (void)testFavoriteExportPreservesStoredPoiTagsWithoutReinterpretingThem
{
    NSDictionary *stored = @{@"amenity_type": @"healthcare", @"amenity_subtype": @"pharmacy",
                             @"amenity_opening_hours": @"Mo,We 08:00-22:00; Sa 10:00-12:00",
                             @"osm_tag_check_date_opening_hours": @"2025-03-28", @"osm_tag_check_date": @"2025-11-18",
                             @"osm_tag_collapsable_payment_type": @"payment_cash;payment_credit_cards"};
    OAFavoriteItem *favorite = [[OAFavoriteItem alloc] initWithLat:50.4 lon:30.5 name:@"Stored POI" category:@""];
    [favorite setExtensions:stored];
    for (NSUInteger pass = 0; pass < 3; pass++)
    {
        OASWptPt *point = [favorite toWpt];
        for (NSString *key in stored)
            XCTAssertEqualObjects([point getExtensionsToRead][key], stored[key]);
        favorite = [OAFavoriteItem fromWpt:point category:@""];
    }
}

- (void)testFavoriteWaypointGpxRoundTripKeepsGroupedPaymentMethods
{
    NSString *paymentKey = [COLLAPSABLE_PREFIX stringByAppendingString:@"payment_type"];
    NSSet<NSString *> *expected = [NSSet setWithArray:@[@"payment_cash_yes", @"payment_visa_yes"]];
    OAPOI *poi = [[OAPOI alloc] init];
    [poi setAdditionalInfo:@{@"payment_cash_yes": @"yes", @"payment_visa_yes": @"yes"}];
    OAFavoriteItem *favorite = [[OAFavoriteItem alloc] initWithLat:50.4 lon:30.5 name:@"Payment methods" category:@""];
    [favorite setAmenity:poi];

    OASWptPt *point = [favorite toWpt];
    NSString *groupedPaymentMethods = [point getExtensionsToRead][paymentKey];
    XCTAssertNotNil(groupedPaymentMethods);
    NSArray<NSString *> *methods = [groupedPaymentMethods componentsSeparatedByString:@";"] ?: @[];
    XCTAssertEqual(methods.count, expected.count);
    XCTAssertEqualObjects([NSSet setWithArray:methods], expected);

    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"gpx"]];
    [self addTeardownBlock:^{
        [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    }];
    OASKFile *file = [[OASKFile alloc] initWithFilePath:path];
    OASGpxFile *gpx = [[OASGpxFile alloc] initWithAuthor:@"test"];
    [gpx addPointPoint:point];
    XCTAssertNil([OASGpxUtilities.shared writeGpxFileFile:file gpxFile:gpx]);

    OASGpxFile *reloadedGpx = [OASGpxUtilities.shared loadGpxFileFile:file];
    XCTAssertNil(reloadedGpx.error);
    OASWptPt *reloadedPoint = [reloadedGpx getPointsList].firstObject;
    XCTAssertNotNil(reloadedPoint);
    XCTAssertEqualObjects([reloadedPoint getExtensionsToRead][paymentKey], groupedPaymentMethods);
    if (!reloadedPoint)
        return;

    OAFavoriteItem *restored = [OAFavoriteItem fromWpt:reloadedPoint category:@""];
    XCTAssertEqualObjects([[restored getAmenity] getAdditionalInfo:paymentKey], groupedPaymentMethods);
    OAFavoriteViewController *controller = [[OAFavoriteViewController alloc] initWithItem:restored headerOnly:NO];
    NSMutableArray<OAAmenityInfoRow *> *rows = [NSMutableArray array];
    [controller buildInternal:rows];
    NSArray *paymentRows = [rows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"key == %@", @"payment_type"]];
    XCTAssertEqual(paymentRows.count, 1);
}

- (void)testPlainCollapsableLabelsKeepTheirMeasuredHeight
{
    for (NSString *text in @[@"123 m", @"Long localized description with several words and a second sentence.", @"Mo, We 09:00-18:00; Sa 10:00-12:00", @"Описание на русском\nДругий рядок українською"])
    {
        for (NSNumber *width in @[@240, @390, @700])
        {
            OACollapsableLabelView *view = [[OACollapsableLabelView alloc] initWithText:text collapsed:YES];
            [view adjustHeightForWidth:width.doubleValue];
            CGSize expected = [OAUtilities calculateTextBounds:text width:view.label.bounds.size.width font:view.label.font];
            XCTAssertEqualWithAccuracy(view.label.bounds.size.height, MAX(expected.height, 21.0), 0.01);
            XCTAssertEqualObjects(view.label.text, text);
        }
    }
}

@end
