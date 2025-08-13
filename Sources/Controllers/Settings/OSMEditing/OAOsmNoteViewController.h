//
//  OAOsmNoteViewController.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseButtonsViewController.h"
#import "OAOsmEditingViewController.h"

@class OAOsmPoint, OAOsmEditingPlugin;

@protocol OAOsmEditingBottomSheetDelegate;

typedef NS_ENUM(NSInteger, EOAOSMNoteScreenType)
{
    EOAOsmNoteViewConrollerModeCreate = 0,
    EOAOsmNoteViewConrollerModeUpload,
    EOAOsmNoteViewConrollerModeModify,
    EOAOsmNoteViewConrollerModeClose,
    EOAOsmNoteViewConrollerModeReopen
};

@interface OAOsmNoteViewController : OABaseButtonsViewController

@property (nonatomic) id<OAOsmEditingBottomSheetDelegate> delegate;

- (instancetype)initWithEditingPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray *)points type:(EOAOSMNoteScreenType)type;

@end
