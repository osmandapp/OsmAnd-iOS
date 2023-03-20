//
//  OARoutingFile.h
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutingDataObject;

@interface OARoutingFile : NSObject

@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) NSArray<OARoutingDataObject *> *profiles;

- (instancetype)initWithFileName:(NSString *)fileName;

- (void)addProfile:(OARoutingDataObject *)profile;

@end
