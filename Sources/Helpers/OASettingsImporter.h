//
//  OASettingsImporter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"
#import "OASettingsCollect.h"
#import "OACheckDuplicates.h"
#import "OASettingsImport.h"

#pragma mark - OASettingsImporter

//@class OASettingsItem;

@interface OASettingsImporter : NSObject

- (instancetype) initWithApp;

@end

#pragma mark - OASettingsItemsFactory

@interface OASettingsItemsFactory : NSObject

- (instancetype) initWithJSON:(NSString*)jsonStr;
- (NSArray<OASettingsItem *> *) getItems;

@end

#pragma mark - OAImportAsyncTask

@interface OAImportAsyncTask : NSObject

- (instancetype) initWithFile:(NSString*)filePath latestChanges:(NSString*)latestChanges version:(NSInteger)version
              collectListener:(OASettingsCollect*)collectListener;
- (instancetype) initWithFile:(NSString*)filePath items:(NSMutableArray<OASettingsItem *>*)items latestChanges:(NSString*)latestChanges version:(NSInteger)version importListener:(OASettingsImport*) importListener;
- (instancetype) initWithFile:(NSString*)filePath items:(NSMutableArray<OASettingsItem *>*)items selectedItems:(NSMutableArray<OASettingsItem *>*)selectedItems duplicatesListener:(OACheckDuplicates*) duplicatesListener;
- (void) executeParameters;
- (NSMutableArray<OASettingsItem *> *) getItems;
- (NSString *) getFile;
- (EOAImportType) getImportType;
- (BOOL) isImportDone;
- (NSArray<id>*) getDuplicates;
- (NSMutableArray<OASettingsItem *> *) getSelectedItems;
- (NSArray<id>*) getDuplicatesData:(NSMutableArray<OASettingsItem *> *)items;

@end

#pragma mark - OAImportItemsAsyncTask

@interface OAImportItemsAsyncTask : NSObject

- (instancetype) initWithFile:(NSString *)file listener:()listener items:(NSMutableArray<OASettingsItem*>*)items;
- (void) executeParameters;

@end
