//
//  OAOsmNoteBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/4/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//


#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmEditingViewController.h"

@class OAOsmNoteBottomSheetViewController;
@class OAOsmPoint;
@class OAOsmEditingPlugin;

typedef NS_ENUM(NSInteger, EOAOSMNoteBottomSheetType)
{
    TYPE_CREATE = 0,
    TYPE_UPLOAD
};

@interface OAOsmNoteBottomSheetScreen : NSObject<OABottomSheetScreen>

@property (nonatomic) EOAAction action;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmNoteBottomSheetViewController *)viewController
               param:(id)param
              action:(EOAAction)action;

@end

@interface OAOsmNoteBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) OAOsmPoint *osmPoint;
@property (nonatomic, readonly) EOAOSMNoteBottomSheetType type;

- (id) initWithEditingPlugin:(OAOsmEditingPlugin *)plugin point:(OAOsmPoint *)point action:(EOAAction)action type:(EOAOSMNoteBottomSheetType)type;

@end

@protocol OAOsmNoteForwardingDelegate <NSObject>

@required

- (void) setMessageText:(NSString *)text;

- (void) refreshData;

@end
