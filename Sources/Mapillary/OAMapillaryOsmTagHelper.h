//
//  OAMapillaryOsmTagHelper.h
//  OsmAnd
//
//  Created by Skalii on 21.02.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMapillaryOsmTagHelper : NSObject

+ (void)downloadImageByKey:(NSString *)key
          onDataDownloaded:(void (^)(NSDictionary *data))onDataDownloaded;

@end
