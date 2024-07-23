//
//  OACopyProfileBottomSheetViewControler.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 05.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OAApplicationMode;

@protocol OACopyProfileBottomSheetDelegate <NSObject>

@required

- (void) onCopyProfileCompleted;

@optional

- (void) onCopyProfile:(OAApplicationMode *)fromAppMode;

@end

@interface OACopyProfileBottomSheetViewControler : OABaseBottomSheetViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) id<OACopyProfileBottomSheetDelegate> delegate;

- (instancetype) initWithMode:(OAApplicationMode *)am;

@end
