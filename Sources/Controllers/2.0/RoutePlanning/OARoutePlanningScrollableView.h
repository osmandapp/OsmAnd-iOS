//
//  OARoutePlanningScrollableView.h
//  OsmAnd
//
//  Created by Paul on 17.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAScrollableTableToolBarView.h"

@protocol OARoutePlanningViewDelegate <NSObject>

- (void) onOptionsPressed;
- (void) onAddPointPressed;
- (void) onUndoPressed;
- (void) onRedoPressed;

@end

@interface OARoutePlanningScrollableView : OAScrollableTableToolBarView

@property (nonatomic, weak) id<OARoutePlanningViewDelegate> routePlanningDelegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
