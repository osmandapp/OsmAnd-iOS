//
//  OASearchAlgorithms.h
//  OsmAnd
//
//  Created by Ivan Pyrohivskyi on 15.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OASearchAlgorithms : NSObject

+ (NSString *) removeApostrophes:(NSString *)s;
+ (NSString *) replaceGermanSS:(NSString *)fullText;

@end