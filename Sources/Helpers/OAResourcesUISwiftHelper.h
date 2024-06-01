//
//  OAResourcesUISwiftHelper.h
//  OsmAnd
//
//  Created by nnngrach on 25.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

// Swift can't use OAResourceItem OAResourcesUIHelper because they have cpp in headers.
// So we can use this adapter for new Swit classes

@class OAWorldRegion, FFCircularProgressView;


@interface OAResourceSwiftItem : NSObject

@property (nonatomic) id objcResourceItem;

- (instancetype) initWithItem:(id)objcResourceItem;

- (NSString *) resourceId;
- (NSString *) title;
- (NSString *) type;
- (NSString *) formatedSize;
- (NSString *) formatedSizePkg;
- (UIImage *) icon;
- (BOOL) isInstalled;

@end


@interface OAResourcesUISwiftHelper : NSObject

+ (OAWorldRegion *) worldRegionByScopeId:(NSString *)regionId;
+ (NSNumber *) resourceTypeByScopeId:(NSString *)scopeId;

+ (NSArray<OAResourceSwiftItem *> *) getResourcesInRepositoryIdsByRegionId:(NSString *)regionId resourceTypeNames:(NSArray<NSString *> *)resourceTypeNames;
+ (NSArray<OAResourceSwiftItem *> *) getResourcesInRepositoryIdsByRegion:(OAWorldRegion *)region resourceTypes:(NSArray<NSNumber *> *)resourceTypes;

+ (UIBezierPath *) tickPath:(FFCircularProgressView *)progressView;

@end
