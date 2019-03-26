//
//  OAOsmEditingViewController.h
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAOpenStreetMapUtilsProtocol.h"

@class OAEntity;
@class OAEditPOIData;

@protocol OAOsmEditingDataProtocol <NSObject>

@required
-(OAEditPOIData *) getData;

@end

@protocol OAOsmEditingBottomSheetDelegate <NSObject>

-(void) dismissEditingScreen;

@end

@interface OAOsmEditingViewController : OACompoundViewController

+(void)commitEntity:(EOAAction)action
             entity:(OAEntity *)entity
         entityInfo:(OAEntityInfo *)info
            comment:(NSString *)comment shouldClose:(BOOL)closeCnageset
        editingUtil:(id<OAOpenStreetMapUtilsProtocol>)util
        changedTags:(NSSet *)changedTags
           callback:(void(^)(void))callback;

+ (void) savePoi:(NSString *)comment
         poiData:(OAEditPOIData *)poiData
     editingUtil:(id<OAOpenStreetMapUtilsProtocol>)editingUtil
  closeChangeSet:(BOOL)closeChangeset;

-(id) initWithLat:(double)latitude lon:(double)longitude;
-(id) initWithEntity:(OAEntity *)entity;

@end

