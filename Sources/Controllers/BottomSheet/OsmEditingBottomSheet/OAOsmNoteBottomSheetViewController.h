//
//  OAOsmNoteBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/4/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//


#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmEditingViewController.h"

@class OAOsmNoteBottomSheetViewController;
@class OAOsmPoint;
@class OAOsmEditingPlugin;
@class OATextInputFloatingCell;
@class OAPasswordInputFieldCell;

typedef NS_ENUM(NSInteger, EOAOSMNoteBottomSheetType)
{
    TYPE_CREATE = 0,
    TYPE_UPLOAD,
    TYPE_MODIFY,
    TYPE_CLOSE,
    TYPE_REOPEN
};

@interface OAOsmNoteBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmNoteBottomSheetViewController *)viewController
               param:(id)param;

@end

@interface OAOsmNoteBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic) id<OAOsmEditingBottomSheetDelegate> delegate;
@property (nonatomic, readonly) NSArray *osmPoints;
@property (nonatomic, readonly) EOAOSMNoteBottomSheetType type;

+ (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint
                                             text:(NSString *)text
                                   roundedCorners:(UIRectCorner)corners
                                    hideUnderline:(BOOL)shouldHide
                     floatingTextFieldControllers:(NSMutableArray *)floatingControllers;

+ (OAPasswordInputFieldCell *)getPasswordCellWithHint:(NSString *)hint text:(NSString *)text roundedCorners:(UIRectCorner)corners hideUnderline:(BOOL)shouldHide floatingTextFieldControllers:(NSMutableArray *)floatingControllers;

- (id) initWithEditingPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray *)points type:(EOAOSMNoteBottomSheetType)type;

@end

@protocol OAOsmNoteForwardingDelegate <NSObject>

@required

- (void) setMessageText:(NSString *)text;

- (void) refreshData;

@end
