//
//  OARemoteFile.h
//  OsmAnd Maps
//
//  Created by Paul on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem;

@interface OARemoteFile : NSObject

@property (nonatomic, readonly, assign) NSInteger userid;
@property (nonatomic, readonly, assign) long identifier;
@property (nonatomic, readonly, assign) NSInteger deviceid;
@property (nonatomic, readonly, assign) NSInteger filesize;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSDate *updatetime;
@property (nonatomic, readonly, assign) long updatetimems;
@property (nonatomic, readonly) NSDate *clienttime;
@property (nonatomic, readonly, assign) long clienttimems;
@property (nonatomic, readonly, assign) NSInteger zipSize;

@property (nonatomic) OASettingsItem *item;

- (instancetype) initWithJson:(NSDictionary *)json;

- (NSString *) getTypeNamePath;

- (BOOL) isInfoFile;
- (BOOL) isDeleted;

@end

NS_ASSUME_NONNULL_END
