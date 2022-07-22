//
//  OAMapCreatorDbHelper.h
//  OsmAnd Maps
//
//  Created by Alexey on 13.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/TileSqliteDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapCreatorDbHelper : NSObject

+ (OAMapCreatorDbHelper *) sharedInstance;

- (void) addSqliteFile:(NSString *)filePath;
- (void) removeSqliteFile:(NSString *)filePath;

- (std::shared_ptr<OsmAnd::TileSqliteDatabase>) getTileSqliteDatabase:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
