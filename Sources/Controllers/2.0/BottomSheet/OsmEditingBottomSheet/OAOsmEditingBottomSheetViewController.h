//
//  OAMoreOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOpenStreetMapUtilsProtocol.h"
#import "OATargetPointView.h"

typedef NS_ENUM(NSInteger, EOAEditingBottomSheetType)
{
    UPLOAD_EDIT = 0,
    DELETE_EDIT
};

@class OAOsmEditingBottomSheetViewController;
@class OAEditPOIData;

@interface OAOsmEditingBottomSheetScreen : NSObject<OABottomSheetScreen>

@property (nonatomic) EOAEditingBottomSheetType editingType;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmEditingBottomSheetViewController *)viewController
                param:(id)param
                type:(EOAEditingBottomSheetType)type;

@end

@interface OAOsmEditingBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (strong, nonatomic) id<OATargetPointViewDelegate> menuViewDelegate;

- (id) initWithEditingUtils:(id<OAOpenStreetMapUtilsProtocol>)editingUtil data:(OAEditPOIData *)data type:(EOAEditingBottomSheetType)type;

-(OAEditPOIData *)getPoiData;

@end

@protocol OAOsmMessageForwardingDelegate <NSObject>

@required

- (void) setMessageText:(NSString *)text;

- (void) refreshData;

@end
