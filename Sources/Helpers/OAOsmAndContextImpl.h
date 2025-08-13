//
//  OAOsmAndContextImpl.h
//  OsmAnd Maps
//
//  Created by Alexey K on 10.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsmAndShared/OsmAndShared.h>

NS_ASSUME_NONNULL_BEGIN

@interface OANameStringMatcherImpl : NSObject<OASKStringMatcher>

- (instancetype)initWithName:(NSString *)name mode:(OASKStringMatcherMode *)mode;

@end

@interface OAOsmAndContextImpl : NSObject<OASOsmAndContext>

@end

NS_ASSUME_NONNULL_END
