//
//  OAActionAddMapStyleViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAQuickSearchListItem;

@protocol OAAddMapStyleDelegate <NSObject>

@required

- (void) onMapStylesSelected:(NSArray *)items;

@end

@interface OAActionAddMapStyleViewController : OACompoundViewController

-(instancetype)initWithNames:(NSMutableArray<NSString *> *)names;

@property (nonatomic) id<OAAddMapStyleDelegate> delegate;

@end
