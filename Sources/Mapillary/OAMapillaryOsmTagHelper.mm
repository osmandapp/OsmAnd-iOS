//
//  OAMapillaryOsmTagHelper.mm
//  OsmAnd
//
//  Created by Skalii on 21.02.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAMapillaryOsmTagHelper.h"
#import "OAMapillaryTilesProvider.h"
#import "OAMapillaryImageViewController.h"

#define GRAPH_URL_ENDPOINT @"https://graph.mapillary.com/"
#define PARAM_ACCESS_TOKEN [NSString stringWithFormat:@"access_token=%@", MAPILLARY_ACCESS_TOKEN]
#define PARAM_FIELDS @"fields=id,geometry,compass_angle,captured_at,camera_type,thumb_256_url,thumb_1024_url"

#define ID @"id"
#define GEOMETRY @"geometry"
#define COORDINATES @"coordinates"
#define COMPASS_ANGLE @"compass_angle"
#define CAPTURED_AT @"captured_at"
#define CAMERA_TYPE @"camera_type"
#define THUMB_256_URL @"thumb_256_url"
#define THUMB_1024_URL @"thumb_1024_url"

@implementation OAMapillaryOsmTagHelper

+ (void)downloadImageByKey:(NSString *)key
          onDataDownloaded:(void (^)(NSDictionary *data))onDataDownloaded
{
    NSString *urlStr = [NSString stringWithFormat:@"%@%@?%@&%@",
            GRAPH_URL_ENDPOINT, key, PARAM_ACCESS_TOKEN, PARAM_FIELDS];
    NSURL *dataURL = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [self fetchFromUrl:dataURL onDownloaded:^(NSData *data) {
        if (data)
        {
            NSDictionary *dicData = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:NULL];
            NSMutableDictionary *result = [NSMutableDictionary dictionary];

            if ([dicData.allKeys containsObject:GEOMETRY])
            {
                NSDictionary *geometry = dicData[GEOMETRY];
                if ([geometry[@"type"] isEqualToString:@"Point"])
                {
                    NSArray<NSNumber *> *coordinates = geometry[COORDINATES];
                    result[@"lat"] = coordinates[1];
                    result[@"lon"] = coordinates[0];
                }
            }

            if ([dicData.allKeys containsObject:CAPTURED_AT])
                result[@"timestamp"] = [dicData[CAPTURED_AT] stringValue];

            if ([dicData.allKeys containsObject:ID])
            {
                NSString *id = dicData[ID];
                result[@"key"] = id;
                result[@"url"] = [NSString stringWithFormat:@"%@%@", MAPILLARY_VIEWER_URL_TEMPLATE, id];
            }

            if ([dicData.allKeys containsObject:COMPASS_ANGLE])
                result[@"ca"] = dicData[COMPASS_ANGLE];

            if ([dicData.allKeys containsObject:CAMERA_TYPE])
            {
                NSString *cameraType = dicData[CAMERA_TYPE];
                BOOL is360 = [cameraType isEqualToString:@"equirectangular"]
                        || [cameraType isEqualToString:@"spherical"];
                result[@"is360"] = @(is360);
            }

            if ([dicData.allKeys containsObject:THUMB_256_URL])
                result[@"imageUrl"] = dicData[THUMB_256_URL];

            if ([dicData.allKeys containsObject:THUMB_1024_URL])
                result[@"imageHiresUrl"] = dicData[THUMB_1024_URL];

            result[@"externalLink"] = @(NO);
            result[@"topIcon"] = @"ic_custom_mapillary_color_logo";

            if (onDataDownloaded)
                onDataDownloaded(result);
        }
    }];
}

+ (void)fetchFromUrl:(NSURL *)dataURL
        onDownloaded:(void (^)(NSData *data))onDownloaded
{
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:dataURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *) response).statusCode == 200 && data)
            onDownloaded(data);
    }] resume];
}

@end
