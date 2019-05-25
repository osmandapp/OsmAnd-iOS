//
//  OAMapillaryImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAImageCard.h"

@implementation OAImageCard

- (id) initWithData:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        _type = data[@"type"];
        _ca = ((NSNumber *) data[@"ca"]).doubleValue;
        _latitude = ((NSNumber *) data[@"lat"]).doubleValue;
        _longitude = ((NSNumber *) data[@"lon"]).doubleValue;
        _timestamp = data[@"timestamp"];
        _key = data[@"key"];
        _title = data[@"title"];
        _userName = data[@"username"];
        _url = data[@"url"];
        _imageUrl = data[@"imageUrl"];
        _imageHiresUrl = data[@"imageHiresUrl"];
        _externalLink = data[@"externalLink"];
    }
    return self;
}

- (void) downloadImage:(void (^)(void))onComplete
{
    NSURL *imgURL = [NSURL URLWithString:_imageUrl];
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:imgURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            if (data) {
                _image = [[UIImage alloc] initWithData:data];
                if (onComplete)
                    onComplete();
            }
        }
    }] resume];
}

@end
