//
//  OAHillshadeLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAHillshadeLayer : NSObject

+ (OAHillshadeLayer *)sharedInstance;

- (void)indexHillshadeFiles;

- (BOOL)exists:(int)x y:(int)y zoom:(int)zoom;
- (NSData *)getBytes:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder;
- (UIImage *)getImage:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder;

@end
