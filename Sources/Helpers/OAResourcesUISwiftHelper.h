//
//  OAResourcesUISwiftHelper.h
//  OsmAnd
//
//  Created by nnngrach on 25.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

// Swift can't use OAResourceItem OAResourcesUIHelper because they have cpp in headers.
// So we can use this adapter for new Swit classes

#import <Foundation/Foundation.h>
#import "OADownloadTask.h"

typedef void (^OADownloadTaskCallback)(id<OADownloadTask> task);

@class OAWorldRegion, FFCircularProgressView;

typedef NS_ENUM(NSInteger, EOAOAResourceSwiftItemType) {
    EOAOAResourceSwiftItemTypeUnknown = -1,
    EOAOAResourceSwiftItemTypeMapRegion = 0,
    EOAOAResourceSwiftItemTypeRoadMapRegion,
    EOAOAResourceSwiftItemTypeSrtmMapRegion,
    EOAOAResourceSwiftItemTypeDepthContourRegion,
    EOAOAResourceSwiftItemTypeDepthMapRegion,
    EOAOAResourceSwiftItemTypeWikiMapRegion,
    EOAOAResourceSwiftItemTypeHillshadeRegion,
    EOAOAResourceSwiftItemTypeSlopeRegion,
    EOAOAResourceSwiftItemTypeHeightmapRegionLegacy,
    EOAOAResourceSwiftItemTypeGeoTiffRegion,
    EOAOAResourceSwiftItemTypeLiveUpdateRegion,
    EOAOAResourceSwiftItemTypeVoicePack,
    EOAOAResourceSwiftItemTypeMapStyle,
    EOAOAResourceSwiftItemTypeMapStylesPresets,
    EOAOAResourceSwiftItemTypeOnlineTileSources,
    EOAOAResourceSwiftItemTypeGpxFile,
    EOAOAResourceSwiftItemTypeSqliteFile,
    EOAOAResourceSwiftItemTypeWeatherForecast,
    EOAOAResourceSwiftItemTypeTravel
};


@interface OAResourceSwiftItem : NSObject

@property (nonatomic) id objcResourceItem;

- (instancetype) initWithItem:(id)objcResourceItem;

- (NSString *) resourceId;
- (NSString *) title;
- (NSString *) type;
- (EOAOAResourceSwiftItemType) resourceType;
- (NSString *) formatedSize;
- (NSString *) formatedSizePkg;
- (UIImage *) icon;
- (NSString *) iconName;
- (BOOL) isInstalled;
- (id<OADownloadTask>) downloadTask;
- (void) refreshDownloadTask;

@end


@interface OAMultipleResourceSwiftItem : OAResourceSwiftItem

- (NSArray<OAResourceSwiftItem *> *) items;
- (BOOL) allDownloaded;
- (OAResourceSwiftItem *) getActiveItem:(BOOL)useDefautValue;
- (NSString *) getResourceId;

@end


@interface OAResourcesUISwiftHelper : NSObject

+ (OAWorldRegion *) worldRegionByScopeId:(NSString *)regionId;
+ (NSNumber *) resourceTypeByScopeId:(NSString *)scopeId;

+ (NSArray<OAResourceSwiftItem *> *) getResourcesInRepositoryIdsByRegionId:(NSString *)regionId resourceTypeNames:(NSArray<NSString *> *)resourceTypeNames;
+ (NSArray<OAResourceSwiftItem *> *) getResourcesInRepositoryIdsByRegion:(OAWorldRegion *)region resourceTypes:(NSArray<NSNumber *> *)resourceTypes;

+ (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView;

+ (void)offerDownloadAndInstallOf:(OAResourceSwiftItem *)item
                    onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                    onTaskResumed:(OADownloadTaskCallback)onTaskResumed;

+ (void)offerDownloadAndInstallOf:(OAResourceSwiftItem *)item
                    onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                    onTaskResumed:(OADownloadTaskCallback)onTaskResumed
                completionHandler:(void(^)(UIAlertController *))completionHandler;

+ (void) offerCancelDownloadOf:(OAResourceSwiftItem *)item onTaskStop:(OADownloadTaskCallback)onTaskStop completionHandler:(void(^)(UIAlertController *))completionHandler;

+ (void)offerMultipleDownloadAndInstallOf:(OAMultipleResourceSwiftItem *)multipleItem
                            selectedItems:(NSArray<OAResourceSwiftItem *> *)selectedItems
                            onTaskCreated:(OADownloadTaskCallback)onTaskCreated
                            onTaskResumed:(OADownloadTaskCallback)onTaskResumed;

+ (void)checkAndDeleteOtherSRTMResources:(NSArray<OAResourceSwiftItem *> *)itemsToCheck;

+ (void) onDownldedResourceInstalled;

@end
