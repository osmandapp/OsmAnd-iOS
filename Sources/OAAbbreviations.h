//
//  OAAbbreviations.h
//  OsmAnd Maps
//
//  Created by plotva on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#ifndef OAAbbreviations_h
#define OAAbbreviations_h

#import <Foundation/Foundation.h>

@interface OAAbbreviations : NSObject

+ (NSString *) replace:(NSString *)word;
+ (NSString *) replaceAll:(NSString *)phrase;

@end

#endif /* OAAbbreviations_h */
