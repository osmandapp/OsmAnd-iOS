//
//  OAProfilesGroup.h
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutingDataObject;

@interface OAProfilesGroup : NSObject

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSArray<OARoutingDataObject *> *profiles;
@property (nonatomic) NSString *descr;

- (instancetype)initWithTitle:(NSString *)title profiles:(NSArray<OARoutingDataObject *> *)profiles;

- (void)sortProfiles;

@end
