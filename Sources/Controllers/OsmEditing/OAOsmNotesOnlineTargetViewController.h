//
//  OAOsmEditViewController.h
//  OsmAnd
//
//  Created by Alexey on 28/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OAOnlineOsmNoteWrapper;

@interface OAOsmNotesOnlineTargetViewController : OATargetInfoViewController

- (instancetype) initWithNote:(OAOnlineOsmNoteWrapper *)point icon:(UIImage *)icon;

@end

