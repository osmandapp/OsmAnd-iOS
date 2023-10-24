//
//  OAOsmUploadPOIViewController.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 21.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseButtonsViewController.h"
#import "OAOsmEditingViewController.h"

@class OAOsmPoint;

@interface OAOsmUploadPOIViewController : OABaseButtonsViewController

@property (strong, nonatomic) id<OAOsmEditingBottomSheetDelegate> delegate;

- (instancetype)initWithPOIItems:(NSArray<OAOsmPoint *> *)points;

@end
