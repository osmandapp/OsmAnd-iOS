//
//  OALocalFIle.h
//  OsmAnd Maps
//
//  Created by Paul on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem;

@interface OALocalFile : NSObject

@property (nonatomic) NSString *filePath;
@property (nonatomic) NSString *fileName;
@property (nonatomic, assign) long uploadTime;
@property (nonatomic, assign) long localModifiedTime;

@property (nonatomic) OASettingsItem *item;

- (NSString *) getTypeFileName;

@end

NS_ASSUME_NONNULL_END
