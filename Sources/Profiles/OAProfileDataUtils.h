//
//  OAProfileDataUtils.h
//  OsmAnd
//
//  Created by nnngrach on 28.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAProfileDataObject, OAApplicationMode;

@interface OAProfileDataUtils : NSObject

+ (NSArray<OAProfileDataObject *> *) getDataObjects:(NSArray<OAApplicationMode *> *)appModes;

@end
