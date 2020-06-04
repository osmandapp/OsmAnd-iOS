//
//  OASelectMapSourceViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "UIKit/UIKit.h"

@protocol OAMapSourceSelectionDelegate <NSObject>

@required

- (void) onNewSourceSelected;

@end

@interface OASelectMapSourceViewController : OACompoundViewController

@property (nonatomic) id<OAMapSourceSelectionDelegate> delegate;

@end

