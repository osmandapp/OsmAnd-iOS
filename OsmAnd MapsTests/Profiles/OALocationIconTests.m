#import <XCTest/XCTest.h>
#import "OALocationIcon.h"
#import "OAApplicationMode.h"

@interface OALocationIconExportMode : OAApplicationMode

@property (nonatomic) OALocationIcon *restingIcon;
@property (nonatomic) OALocationIcon *movingIcon;

@end

@implementation OALocationIconExportMode

- (NSString *)stringKey { return @"icon_export_test"; }
- (NSString *)getUserProfileName { return @"Icon export test"; }
- (NSString *)getIconColorName { return @"BLUE"; }
- (int)getColorToExport { return -1; }
- (NSString *)getIconName { return @"ic_action_car_dark"; }
- (OAApplicationMode *)parent { return nil; }
- (NSString *)getRouterServiceName { return @"OSMAND"; }
- (NSString *)getDerivedProfile { return @"car"; }
- (NSString *)getRoutingProfile { return @"car"; }
- (OALocationIcon *)getLocationIcon { return self.restingIcon; }
- (OALocationIcon *)getNavigationIcon { return self.movingIcon; }
- (double)getLocationIconSize { return 1; }
- (double)getCourseIconSize { return 1; }
- (int)getOrder { return 0; }

@end

@interface OALocationIconTests : XCTestCase
@end

@implementation OALocationIconTests

- (void)testLegacyNamesUseImportContext
{
    NSArray<NSArray<NSString *> *> *cases = @[
        @[@"DEFAULT", @"DEFAULT", @"MOVEMENT_DEFAULT"],
        @[@"CAR", @"CAR", @"MOVEMENT_CAR"],
        @[@"NAUTICAL", @"DEFAULT", @"MOVEMENT_NAUTICAL"],
        @[@"default", @"DEFAULT", @"MOVEMENT_DEFAULT"],
        @[@"car", @"CAR", @"MOVEMENT_CAR"]
    ];
    for (NSArray<NSString *> *values in cases)
    {
        XCTAssertEqualObjects([OALocationIcon locationIconWithName:values[0] forNavigation:NO].name, values[1]);
        XCTAssertEqualObjects([OALocationIcon locationIconWithName:values[0] forNavigation:YES].name, values[2]);
    }
}

- (void)testQualifiedNamesPreserveExplicitFamily
{
    for (OALocationIcon *icon in OALocationIcon.defaultIcons)
    {
        XCTAssertEqual([OALocationIcon locationIconWithName:icon.exportName forNavigation:NO], icon);
        XCTAssertEqual([OALocationIcon locationIconWithName:icon.exportName forNavigation:YES], icon);
    }
    XCTAssertEqualObjects(OALocationIcon.CAR.exportName, @"STATIC_CAR");
    XCTAssertEqualObjects(OALocationIcon.BICYCLE.exportName, @"STATIC_BICYCLE");
    XCTAssertEqualObjects(OALocationIcon.DEFAULT.exportName, @"STATIC_DEFAULT");
}

- (void)testRuntimeLookupPreservesPickerSelections
{
    for (OALocationIcon *icon in OALocationIcon.defaultIcons)
        XCTAssertEqual([OALocationIcon locationIconWithName:icon.name], icon);
}

- (void)testAssetAndModelAliasesPreserveExplicitIcon
{
    for (OALocationIcon *icon in OALocationIcon.defaultIcons)
    {
        for (NSNumber *navigation in @[@NO, @YES])
        {
            XCTAssertEqual([OALocationIcon locationIconWithName:icon.iconName forNavigation:navigation.boolValue], icon);
            XCTAssertEqual([OALocationIcon locationIconWithName:icon.modelName forNavigation:navigation.boolValue], icon);
        }
    }
}

- (void)testInvalidValuesUseContextDefault
{
    NSArray *invalidValues = @[@"", @"UNKNOWN", @42, NSNull.null, @[], @{}];
    for (id value in invalidValues)
    {
        XCTAssertEqual([OALocationIcon locationIconWithName:value forNavigation:NO], OALocationIcon.DEFAULT);
        XCTAssertEqual([OALocationIcon locationIconWithName:value forNavigation:YES], OALocationIcon.MOVEMENT_DEFAULT);
    }
    XCTAssertEqual([OALocationIcon locationIconWithName:nil forNavigation:NO], OALocationIcon.DEFAULT);
    XCTAssertEqual([OALocationIcon locationIconWithName:nil forNavigation:YES], OALocationIcon.MOVEMENT_DEFAULT);
}

- (void)testJSONRoundTripPreservesEveryIconInBothFields
{
    for (OALocationIcon *location in OALocationIcon.defaultIcons)
    {
        for (OALocationIcon *navigation in OALocationIcon.defaultIcons)
        {
            OALocationIconExportMode *mode = [[OALocationIconExportMode alloc] init];
            mode.restingIcon = location;
            mode.movingIcon = navigation;
            NSDictionary *exported = mode.toJson;
            NSData *data = [NSJSONSerialization dataWithJSONObject:exported options:0 error:nil];
            NSDictionary *imported = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            OAApplicationModeBean *bean = [OAApplicationModeBean fromJson:imported];
            XCTAssertEqualObjects(bean.locIcon, location.name);
            XCTAssertEqualObjects(bean.navIcon, navigation.name);
        }
    }
}

- (void)testRestingExportPreservesLegacyNames
{
    OALocationIconExportMode *mode = [[OALocationIconExportMode alloc] init];
    mode.movingIcon = OALocationIcon.MOVEMENT_DEFAULT;
    NSArray<NSString *> *legacyNames = @[@"DEFAULT", @"CAR", @"BICYCLE", @"MOVEMENT_DEFAULT", @"MOVEMENT_NAUTICAL", @"MOVEMENT_CAR"];
    NSArray<OALocationIcon *> *icons = OALocationIcon.defaultIcons;
    for (NSUInteger index = 0; index < icons.count; index++)
    {
        mode.restingIcon = icons[index];
        NSDictionary *exported = mode.toJson;
        XCTAssertEqualObjects(exported[@"locIcon"], legacyNames[index]);
        XCTAssertEqualObjects(exported[@"navIcon"], @"MOVEMENT_DEFAULT");
    }
}

@end

@interface OALocationIconImportTests : XCTestCase
@end

@implementation OALocationIconImportTests

- (void)testProfileImportResolvesLegacyNavigationName
{
    OAApplicationModeBean *bean = [OAApplicationModeBean fromJson:@{@"locIcon": @"CAR", @"navIcon": @"DEFAULT"}];
    XCTAssertEqualObjects(bean.locIcon, @"CAR");
    XCTAssertEqualObjects(bean.navIcon, @"MOVEMENT_DEFAULT");
}

- (void)testProfileImportResolvesAndroidStaticName
{
    OAApplicationModeBean *bean = [OAApplicationModeBean fromJson:@{@"locIcon": @"STATIC_CAR", @"navIcon": @"MOVEMENT_DEFAULT"}];
    XCTAssertEqualObjects(bean.locIcon, @"CAR");
    XCTAssertEqualObjects(bean.navIcon, @"MOVEMENT_DEFAULT");
}

- (void)testProfileImportPreservesExplicitOppositeFamilies
{
    OAApplicationModeBean *bean = [OAApplicationModeBean fromJson:@{@"locIcon": @"MOVEMENT_CAR", @"navIcon": @"STATIC_DEFAULT"}];
    XCTAssertEqualObjects(bean.locIcon, @"MOVEMENT_CAR");
    XCTAssertEqualObjects(bean.navIcon, @"DEFAULT");
}

@end
