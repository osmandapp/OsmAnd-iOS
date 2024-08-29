//
//  OASharedUtil.h
//  OsmAnd Maps
//
//  Created by Alexey K on 14.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <OsmAndShared/OsmAndShared.h>

NS_ASSUME_NONNULL_BEGIN
//@class OASGpxFile;
@interface OASharedUtil : NSObject

+ (void)initSharedLib:(NSString *)documentsPath gpxPath:(NSString *)gpxPath;
//+ (OASGpxFile *)loadGpx:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
