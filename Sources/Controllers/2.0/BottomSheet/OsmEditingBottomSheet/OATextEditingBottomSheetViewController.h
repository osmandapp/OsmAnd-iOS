//
//  OAMoreOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOpenStreetMapUtilsProtocol.h"
#import "OAOsmEditingBottomSheetViewController.h"

@class OATextEditingBottomSheetViewController;
@class OATextInputFloatingCell;

typedef NS_ENUM(NSInteger, EOATextInputBottomSheetType)
{
    MESSAGE_INPUT = 0,
    USERNAME_INPUT,
    PASSWORD_INPUT
};

@interface OATextEditingBottomSheetScreen : NSObject<OABottomSheetScreen>

- (id) initWithTable:(UITableView *)tableView viewController:(OATextEditingBottomSheetViewController *)viewController
                param:(id)param;

-(void) doneButtonPressed;

@end

@interface OATextEditingBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (strong, nonatomic) id<OAOsmMessageForwardingDelegate> messageDelegate;
@property (nonatomic) EOATextInputBottomSheetType inputType;

- (id) initWithTitle:(NSString *)cellTitle placeholder:(NSString *)placeholder type:(EOATextInputBottomSheetType)type;


@end
