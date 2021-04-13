//
//  OAExportSettingsCategory.h
//  OsmAnd
//
//  Created by Paul on 27.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAExportSettingsCategory : NSObject

@property (nonatomic, readonly) NSString *title;

+ (OAExportSettingsCategory *) SETTINGS;
+ (OAExportSettingsCategory *) MY_PLACES;
+ (OAExportSettingsCategory *) RESOURCES;

@end

NS_ASSUME_NONNULL_END
