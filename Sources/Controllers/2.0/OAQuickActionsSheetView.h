//
//  OAQuickActionsSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAQuickActionsSheetDelegate <NSObject>

@required

- (void) dismissBottomSheet;

@end

@interface OAQuickActionsSheetView : UIView

@property (nonatomic) id<OAQuickActionsSheetDelegate> delegate;

@end
