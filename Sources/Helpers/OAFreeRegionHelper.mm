//
//  OAFreeRegionHelper.mm
//  OsmAnd
//
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

#import "OAFreeRegionHelper.h"
#import <MBProgressHUD.h>
#import "OsmAndApp.h"
#import "OAWorldRegion.h"
#import "OAIAPHelper.h"
#import "OAAppSettings.h"
#import "OAAppVersion.h"
#import "OAResourcesUIHelper.h"
#import "OAChoosePlanHelper.h"
#import "OARootViewController.h"
#import "OANetworkUtilities.h"
#import "OALocationServices.h"
#import "OAObservable.h"
#import "Localization.h"
#include <OsmAndCore/ResourcesManager.h>

static NSString * const kFreeRegionFile = @"free_region.plist";
static NSString * const kRegionKey = @"region";
static NSString * const kMigratedKey = @"migrated";
static NSString * const kUpdateWarningShownKey = @"update_warning_shown";
static NSString * const kProtoReplacesUsedKey = @"proto_replaces_used";
static NSString * const kProtoAnswerKey = @"proto_answer";

static NSString * const kReplaceUrl = @"https://osmand.net/api/replace-download-map";

// Maps built before 01.07.2026 do not work with the new search
static const uint64_t kNewSearchMapsTimestamp = 1782864000000ULL;
static const NSTimeInterval kFakeNetworkDelay = 1.2;

@implementation OAFreeRegionHelper

+ (NSArray<NSString *> *) federations
{
    static NSArray<NSString *> *federations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        federations = @[@"northamerica_us", @"northamerica_canada", @"russia", @"southamerica_brazil",
                        @"asia_india", @"asia_china", @"australia-oceania-all_australia-oceania"];
    });
    return federations;
}

#pragma mark - Storage

// Own file excluded from the backup, not OAAppSettings: the free region must not come back from a
// backup or travel to another device with OsmAnd Cloud.
+ (NSURL *) storageUrl
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *dir = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    [fileManager createDirectoryAtURL:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return [dir URLByAppendingPathComponent:kFreeRegionFile];
}

+ (NSMutableDictionary *) loadStorage
{
    NSDictionary *storage = [NSDictionary dictionaryWithContentsOfURL:[self storageUrl]];
    return storage ? [storage mutableCopy] : [NSMutableDictionary dictionary];
}

+ (id) storedValue:(NSString *)key
{
    return [self loadStorage][key];
}

+ (void) storeValue:(id)value forKey:(NSString *)key
{
    NSMutableDictionary *storage = [self loadStorage];
    if (value)
        storage[key] = value;
    else
        [storage removeObjectForKey:key];
    NSURL *url = [self storageUrl];
    [storage writeToURL:url atomically:YES];
    [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
}

#pragma mark - Free region

+ (BOOL) isFreeVersion
{
    return ![OAIAPHelper isPaidVersion];
}

+ (OAWorldRegion *) getFreeRegion
{
    [self migrateIfNeeded];
    NSString *regionId = [self storedValue:kRegionKey];
    return regionId.length > 0 ? [OsmAndApp.instance.worldRegion getFlattenedSubregion:regionId] : nil;
}

+ (void) setFreeRegion:(OAWorldRegion *)region
{
    [self storeValue:region.regionId forKey:kRegionKey];
}

+ (OAWorldRegion *) getFreeRegionOf:(OAWorldRegion *)region
{
    // the world, Antarctica and the areas of the old region in-apps stay free
    if (!region || !region.regionId || [region isInPurchasedArea])
        return nil;

    OAWorldRegion *world = OsmAndApp.instance.worldRegion;
    NSMutableArray<OAWorldRegion *> *path = [NSMutableArray array];
    for (OAWorldRegion *r = region; r && r != world; r = r.superregion)
        [path insertObject:r atIndex:0];
    if (path.count == 0)
        return nil;

    // under a continent, or a top region that is not a continent (Russia)
    NSUInteger countryIndex = [path.firstObject isContinent] ? 1 : 0;
    if (path.count <= countryIndex)
        return nil;
    OAWorldRegion *country = path[countryIndex];
    if ([[self federations] containsObject:country.regionId] && path.count > countryIndex + 1)
        return path[countryIndex + 1];
    return country;
}

+ (BOOL) isDownloadFree:(OAWorldRegion *)region
{
    if (![self isFreeVersion])
        return YES;
    OAWorldRegion *mapRegion = [self getFreeRegionOf:region];
    if (!mapRegion)
        return YES;
    OAWorldRegion *freeRegion = [self getFreeRegion];
    // the first map chooses the free region, without a dialog
    return !freeRegion || [freeRegion.regionId isEqualToString:mapRegion.regionId];
}

+ (void) chooseFreeRegionOf:(OAWorldRegion *)region
{
    OAWorldRegion *mapRegion = [self getFreeRegionOf:region];
    if ([self isFreeVersion] && mapRegion)
        [self setFreeRegion:mapRegion];
}

+ (void) onMapInstalled:(OAWorldRegion *)region
{
    if ([self isFreeVersion] && ![self getFreeRegion])
        [self chooseFreeRegionOf:region];
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *) collectLocalMaps
{
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *result = [NSMutableDictionary dictionary];
    OsmAndAppInstance app = OsmAndApp.instance;
    for (const auto& localResource : app.resourcesManager->getLocalResources())
    {
        if (localResource->origin != OsmAnd::ResourcesManager::ResourceOrigin::Installed
            || localResource->type != OsmAnd::ResourcesManager::ResourceType::MapRegion)
            continue;
        OAWorldRegion *resourceRegion = [OAResourcesUIHelper findRegionOrAnySubregionOf:app.worldRegion
                                                                   thatContainsResource:localResource->id];
        OAWorldRegion *mapRegion = [self getFreeRegionOf:resourceRegion];
        if (!mapRegion)
            continue;
        NSMutableArray<NSString *> *ids = result[mapRegion.regionId];
        if (!ids)
        {
            ids = [NSMutableArray array];
            result[mapRegion.regionId] = ids;
        }
        [ids addObject:localResource->id.toNSString()];
    }
    return result;
}

+ (uint64_t) sizeOfResources:(NSArray<NSString *> *)resourceIds
{
    uint64_t size = 0;
    for (NSString *resourceId in resourceIds)
    {
        const auto resource = OsmAndApp.instance.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
        if (resource)
            size += resource->size;
    }
    return size;
}

// The old free version counted 7 downloads of any region. An existing user gets the region of their
// current location if they have its maps, otherwise the region with the most map data. Everything
// already installed stays and keeps free updates; a wrong choice is fixed by a replace.
+ (void) migrateIfNeeded
{
    if ([[self storedValue:kMigratedKey] boolValue] || ![self isFreeVersion] || !OsmAndApp.instance.worldRegion)
        return;
    [self storeValue:@YES forKey:kMigratedKey];
    if ([[self storedValue:kRegionKey] length] > 0)
        return;

    NSDictionary<NSString *, NSArray<NSString *> *> *maps = [self collectLocalMaps];
    if (maps.count == 0)
        return;

    NSString *regionId = nil;
    CLLocation *location = OsmAndApp.instance.locationServices.lastKnownLocation;
    if (location)
    {
        for (OAWorldRegion *region in [OsmAndApp.instance.worldRegion queryAtLat:location.coordinate.latitude
                                                                              lon:location.coordinate.longitude])
        {
            OAWorldRegion *mapRegion = [self getFreeRegionOf:region];
            if (mapRegion && maps[mapRegion.regionId])
            {
                regionId = mapRegion.regionId;
                break;
            }
        }
    }
    if (!regionId)
    {
        uint64_t maxSize = 0;
        for (NSString *candidate in maps)
        {
            uint64_t size = [self sizeOfResources:maps[candidate]];
            if (!regionId || size > maxSize)
            {
                maxSize = size;
                regionId = candidate;
            }
        }
    }
    [self storeValue:regionId forKey:kRegionKey];
}

#pragma mark - Update warning

+ (BOOL) shouldShowUpdateWarning
{
    if ([[self storedValue:kUpdateWarningShownKey] boolValue])
        return NO;
    for (const auto& localResource : OsmAndApp.instance.resourcesManager->getLocalResources())
    {
        if (localResource->origin != OsmAnd::ResourcesManager::ResourceOrigin::Installed
            || localResource->type != OsmAnd::ResourcesManager::ResourceType::MapRegion)
            continue;
        const auto installed = std::static_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);
        if (installed->timestamp < kNewSearchMapsTimestamp)
            return YES;
    }
    return NO;
}

+ (void) setUpdateWarningShown
{
    [self storeValue:@YES forKey:kUpdateWarningShownKey];
}

#pragma mark - Server

// PROTOTYPE: until /api/replace-download-map is deployed the answer is simulated on the device - the
// first replace is allowed, the next ones are not; proto_answer ("allow" / "deny") forces it.
+ (void) requestReplaceFrom:(OAWorldRegion *)from to:(OAWorldRegion *)to completion:(void (^)(BOOL allowed))completion
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"package"] = NSBundle.mainBundle.bundleIdentifier ?: @"";
    params[@"version"] = OAAppVersion.getVersion;
    params[@"os"] = @"ios";
    params[@"lang"] = app.getLanguageCode;
    params[@"nd"] = [NSString stringWithFormat:@"%d", app.getAppInstalledDays];
    params[@"ns"] = [NSString stringWithFormat:@"%d", app.getAppExecCount];
    NSString *aid = app.getUserIosId;
    if (aid.length > 0)
        params[@"aid"] = aid;
    params[@"from"] = from.regionId;
    params[@"to"] = to.regionId;

    [OANetworkUtilities sendRequestWithUrl:kReplaceUrl params:params post:NO async:YES onComplete:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSNumber *allowed = nil;
        if (!error && data && [response isKindOfClass:NSHTTPURLResponse.class] && ((NSHTTPURLResponse *) response).statusCode == 200)
        {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([json isKindOfClass:NSDictionary.class])
                allowed = @([[json[@"status"] description] caseInsensitiveCompare:@"ok"] == NSOrderedSame);
        }
        NSString *forced = [self storedValue:kProtoAnswerKey];
        BOOL hasForcedAnswer = [forced isEqualToString:@"allow"] || [forced isEqualToString:@"deny"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (allowed && !hasForcedAnswer)
                completion(allowed.boolValue);
            else
                [self simulateReplace:completion];
        });
    }];
}

+ (void) simulateReplace:(void (^)(BOOL allowed))completion
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (kFakeNetworkDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        int used = [[self storedValue:kProtoReplacesUsedKey] intValue];
        NSString *forced = [self storedValue:kProtoAnswerKey];
        BOOL allowed = [forced isEqualToString:@"allow"] || (![forced isEqualToString:@"deny"] && used < 1);
        if (allowed)
            [self storeValue:@(used + 1) forKey:kProtoReplacesUsedKey];
        completion(allowed);
    });
}

// PROTOTYPE: the real request is https://osmand.net/subscription/register_email (see
// OAManageResourcesViewController doSubscribe:) - not called, a test address must not land in the mailing list.
+ (void) registerEmail:(NSString *)email completion:(dispatch_block_t)completion
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (kFakeNetworkDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[OAAppSettings sharedManager].emailSubscribed set:YES];
        completion();
    });
}

+ (void) applyReplace:(OAWorldRegion *)region
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *maps = [[self collectLocalMaps] mutableCopy];
    [maps removeObjectForKey:region.regionId];
    [self setFreeRegion:region];
    for (NSArray<NSString *> *resourceIds in maps.allValues)
    {
        for (NSString *resourceId in resourceIds)
            app.resourcesManager->uninstallResource(QString::fromNSString(resourceId));
    }
    if (maps.count > 0)
        [app.localResourcesChangedObservable notifyEvent];
}

@end

@implementation OAFreeRegionDialogs

+ (UIViewController *) topViewController
{
    UIViewController *controller = OARootViewController.instance;
    while (controller.presentedViewController)
        controller = controller.presentedViewController;
    return controller;
}

+ (void) present:(UIViewController *)controller
{
    [[self topViewController] presentViewController:controller animated:YES completion:nil];
}

+ (void) showChoosePlan
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.UNLIMITED_MAP_DOWNLOADS
                                          navController:OARootViewController.instance.navigationController];
}

+ (void) showOtherRegion:(OAWorldRegion *)region onReplaced:(dispatch_block_t)onReplaced
{
    OAWorldRegion *newRegion = [OAFreeRegionHelper getFreeRegionOf:region];
    OAWorldRegion *freeRegion = [OAFreeRegionHelper getFreeRegion];
    if (!newRegion || !freeRegion)
        return;

    NSMutableString *message = [NSMutableString stringWithFormat:OALocalizedString(@"free_region_other_descr"), freeRegion.name, newRegion.name];
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *toDelete = [[OAFreeRegionHelper collectLocalMaps] mutableCopy];
    [toDelete removeObjectForKey:newRegion.regionId];
    if (toDelete.count > 0)
    {
        [message appendFormat:@"\n\n%@", OALocalizedString(@"free_region_replace_note")];
        for (NSString *regionId in toDelete)
        {
            OAWorldRegion *deleted = [OsmAndApp.instance.worldRegion getFlattenedSubregion:regionId];
            NSString *size = [NSByteCountFormatter stringFromByteCount:[OAFreeRegionHelper sizeOfResources:toDelete[regionId]]
                                                            countStyle:NSByteCountFormatterCountStyleFile];
            NSString *maps = [NSString stringWithFormat:OALocalizedString(@"free_region_maps_size"), (int) toDelete[regionId].count, size];
            [message appendFormat:@"\n• %@: %@", deleted.name ?: regionId, maps];
        }
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:OALocalizedString(@"free_region_other_title"), newRegion.name]
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"free_region_get_maps_plus") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showChoosePlan];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *replace = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_replace") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self requestReplaceFrom:freeRegion to:newRegion onReplaced:onReplaced];
    }];
    [alert addAction:replace];
    alert.preferredAction = replace;
    [self present:alert];
}

+ (void) requestReplaceFrom:(OAWorldRegion *)from to:(OAWorldRegion *)to onReplaced:(dispatch_block_t)onReplaced
{
    MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:[self topViewController].view animated:YES];
    progress.labelText = OALocalizedString(@"shared_string_loading");
    [OAFreeRegionHelper requestReplaceFrom:from to:to completion:^(BOOL allowed) {
        [progress hide:YES];
        if (allowed)
        {
            [OAFreeRegionHelper applyReplace:to];
            onReplaced();
        }
        else
        {
            [self showNotEligible:to error:nil onReplaced:onReplaced];
        }
    }];
}

+ (void) showNotEligible:(OAWorldRegion *)to error:(NSString *)error onReplaced:(dispatch_block_t)onReplaced
{
    NSString *title = OALocalizedString(@"free_region_not_eligible_title");
    if ([OAAppSettings sharedManager].emailSubscribed.get)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:OALocalizedString(@"free_region_not_eligible_buy_descr")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        UIAlertAction *buy = [UIAlertAction actionWithTitle:OALocalizedString(@"free_region_get_maps_plus") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self showChoosePlan];
        }];
        [alert addAction:buy];
        alert.preferredAction = buy;
        [self present:alert];
        return;
    }

    NSString *message = OALocalizedString(@"free_region_not_eligible_email_descr");
    if (error)
        message = [NSString stringWithFormat:@"%@\n\n%@", message, error];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = OALocalizedString(@"shared_string_email_address");
        textField.keyboardType = UIKeyboardTypeEmailAddress;
        textField.textContentType = UITextContentTypeEmailAddress;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"free_region_get_maps_plus") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showChoosePlan];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak UIAlertController *weakAlert = alert;
    UIAlertAction *send = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_send") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *email = [weakAlert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (![self isValidEmail:email])
        {
            // an alert closes on any button - show it again with the error
            [self showNotEligible:to error:OALocalizedString(@"osm_live_enter_email") onReplaced:onReplaced];
            return;
        }
        MBProgressHUD *progress = [MBProgressHUD showHUDAddedTo:[self topViewController].view animated:YES];
        progress.labelText = OALocalizedString(@"shared_string_loading");
        [OAFreeRegionHelper registerEmail:email completion:^{
            [progress hide:YES];
            // a left email always allows the replace - no second check by the server
            [OAFreeRegionHelper applyReplace:to];
            onReplaced();
        }];
    }];
    [alert addAction:send];
    alert.preferredAction = send;
    [self present:alert];
}

+ (BOOL) isValidEmail:(NSString *)email
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[^@\\s]+@[^@\\s]+\\.[^@\\s]+"];
    return email.length > 0 && [predicate evaluateWithObject:email];
}

+ (void) showUpdateMapsWarningIfNeeded
{
    if (![OAFreeRegionHelper shouldShowUpdateWarning])
        return;
    [OAFreeRegionHelper setUpdateWarningShown];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"free_region_update_maps_title")
                                                                   message:OALocalizedString(@"free_region_update_maps_descr")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"later") style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *update = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_update") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIViewController *resources = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
        [OARootViewController.instance.navigationController pushViewController:resources animated:YES];
    }];
    [alert addAction:update];
    alert.preferredAction = update;
    [self present:alert];
}

@end
