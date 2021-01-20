//
//  OAActionAddProfileViewController.h
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@protocol OAAddProfileDelegate <NSObject>

@required

- (void) onProfileSelected:(NSArray *)items;

@end

@interface OAActionAddProfileViewController : OACompoundViewController

@property (nonatomic) id<OAAddProfileDelegate> delegate;

-(instancetype)initWithNames:(NSArray<NSString *> *)names;

@end
