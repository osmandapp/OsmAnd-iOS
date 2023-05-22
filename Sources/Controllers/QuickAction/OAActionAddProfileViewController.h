//
//  OAActionAddProfileViewController.h
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAAddProfileDelegate <NSObject>

@required

- (void) onProfileSelected:(NSArray *)items;

@end

@interface OAActionAddProfileViewController : OABaseNavbarViewController

@property (nonatomic) id<OAAddProfileDelegate> delegate;

-(instancetype)initWithNames:(NSArray<NSString *> *)names;

@end
