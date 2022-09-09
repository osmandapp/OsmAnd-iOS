//
//  OAOsmBugResult.h
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAOsmNotePoint;

@interface OAOsmBugResult : NSObject

@property (nonatomic) OAOsmNotePoint *localPoint;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString *warning;

@end

NS_ASSUME_NONNULL_END
