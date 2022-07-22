//
//  OAMapCreatorDbHelper.m
//  OsmAnd Maps
//
//  Created by Alexey on 13.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAMapCreatorDbHelper.h"
#import "OAMapCreatorHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/TileSqliteDatabasesCollection.h>

@implementation OAMapCreatorDbHelper
{
    std::shared_ptr<OsmAnd::TileSqliteDatabasesCollection> _dbCollection;
}

+ (OAMapCreatorDbHelper *) sharedInstance
{
    static dispatch_once_t once;
    static OAMapCreatorDbHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _dbCollection = std::make_shared<OsmAnd::TileSqliteDatabasesCollection>(false, false);
    }
    return self;
}

- (void) addSqliteFile:(NSString *)filePath
{
    _dbCollection->addFile(QString::fromNSString(filePath));
}

- (void) removeSqliteFile:(NSString *)filePath
{
    _dbCollection->removeFile(QString::fromNSString(filePath));
}

- (std::shared_ptr<OsmAnd::TileSqliteDatabase>) getTileSqliteDatabase:(NSString *)filePath
{
    return _dbCollection->getTileSqliteDatabase(QString::fromNSString(filePath));
}

@end
