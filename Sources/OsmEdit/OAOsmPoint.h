//
//  OAOsmPoint.h
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAGroup)
{
    BUG,
    POI
};

typedef NS_ENUM(NSInteger, EOAAction)
{
    CREATE,
    MODIFY,
    DELETE,
    REOPEN
};

@protocol OAOsmPointProtocol <NSObject>

@required

-(long) getId;
-(double) getLatitude;
-(double) getLongitude;
-(EOAGroup) getGroup;

@end


@interface OAOsmPoint : NSObject

@property (readonly) NSDictionary<NSNumber *, NSString *> *stringAction;
@property (readonly) NSDictionary<NSString *, NSNumber *> *actionString;

-(id) init;

-(EOAAction) getAction;
-(NSString *) getActionString;
-(void) setActionString:(NSString *) action;
-(void) setAction:(EOAAction) action;

-(NSString *) toNSString;

@end

NS_ASSUME_NONNULL_END
