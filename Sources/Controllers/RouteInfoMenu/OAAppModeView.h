//
//  OAAppModeView.h
//  OsmAnd
//
//  Created by Paul on 09/10/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAApplicationMode.h"
#import "OAAppModeCell.h"

@interface OAAppModeView : UIView

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) id<OAAppModeCellDelegate> delegate;

@property (nonatomic) OAApplicationMode *selectedMode;
@property (nonatomic) BOOL showDefault;

- (void) setupModeButtons;

@end
