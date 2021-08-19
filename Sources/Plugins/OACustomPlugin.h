//
//  OACustomPlugin.h
//  OsmAnd
//
//  Created by Paul on 15.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@class OACustomRegion, OAWorldRegion, OASuggestedDownloadsItem;

@interface OACustomPlugin : OAPlugin

@property (nonatomic) NSString *resourceDirName;
@property (nonatomic, readonly) NSMutableArray<NSString *> *rendererNames;
@property (nonatomic, readonly) NSMutableArray<NSString *> *routerNames;

- (instancetype) initWithJson:(NSDictionary *)json;

- (void) loadResources;
- (void) updateDownloadItems:(NSArray<OAWorldRegion *> *)items;
- (void) updateSuggestedDownloads:(NSArray<OASuggestedDownloadsItem *> *)items;

- (void) writeAdditionalDataToJson:(NSMutableDictionary *)json;
- (void) writeDependentFilesJson:(NSMutableDictionary *)json;

- (void) addRouter:(NSString *)fileName;
- (void) addRenderer:(NSString *)fileName;

- (void) removePluginItems:(void(^)(void))onComplete;
- (NSString *) getPluginDir;

+ (NSArray<OACustomRegion *> *)collectRegionsFromJson:(NSArray *)jsonArray;

@end

NS_ASSUME_NONNULL_END
