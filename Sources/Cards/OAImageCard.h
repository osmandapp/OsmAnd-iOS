//
//  OAMapillaryImageCard.h
//  OsmAnd
//
//  Created by Paul on 5/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAAbstractCard.h"

@interface OAImageCard : OAAbstractCard

@property (nonatomic) NSString *type;
// Image location
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
// (optional) Image's camera angle in range  [0, 360]
@property (nonatomic, readonly) double ca;
// Date When bitmap was captured
@property (nonatomic, readonly) NSString *timestamp;
// Image key
@property (nonatomic, readonly) NSString *key;
// Image title
@property (nonatomic, readonly) NSString *title;
// User name
@property (nonatomic, readonly) NSString *userName;
// Image viewer url
@property (nonatomic, readonly) NSString *url;
// Image bitmap url
@property (nonatomic, readonly) NSString *imageUrl;
// Image high resolution bitmap url
@property (nonatomic, readonly) NSString *imageHiresUrl;
// true if external browser should to be opened, open webview otherwise
@property (nonatomic, readonly) BOOL externalLink;

@property (nonatomic, readonly) NSString *topIcon;

@property (nonatomic) UIImage *image;

- (id) initWithData:(NSDictionary *)data;

- (void) downloadImage;

- (NSString *) getSuitableUrl;

@end
