//
//  OAAppModeCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "OAApplicationMode.h"

@protocol OAAppModeCellDelegate <NSObject>

- (void) appModeChanged:(OAApplicationMode *)mode;

@end

@interface OAAppModeCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) id<OAAppModeCellDelegate> delegate;

@property (nonatomic) OAApplicationMode *selectedMode;
@property (nonatomic) BOOL showDefault;

@end
