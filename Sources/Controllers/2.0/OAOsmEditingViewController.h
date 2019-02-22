//
//  OAOsmEditingViewController.h
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAEntity;
@class OAEditPOIData;

@protocol OAOsmEditingDataProtocol <NSObject>

@required
-(OAEditPOIData *) getData;

@end

@interface OAOsmEditingViewController : OACompoundViewController

-(id) initWithLat:(double)latitude lon:(double)longitude;
-(id) initWithEntity:(OAEntity *)entity;

@end

NS_ASSUME_NONNULL_END
