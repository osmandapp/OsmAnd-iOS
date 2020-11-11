//
//  OACopyProfileBottomSheetViewControler.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 05.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseBottomSheetViewController.h"
#import "OAApplicationMode.h"

@protocol OACopyProfileBottomSheetDelegate <NSObject>

@required

- (void) onCopyProfileCompleted;

@end

@interface OACopyProfileBottomSheetViewControler : OABaseBottomSheetViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id<OACopyProfileBottomSheetDelegate> delegate;

- (instancetype) initWithMode:(OAApplicationMode *)am;

@end
