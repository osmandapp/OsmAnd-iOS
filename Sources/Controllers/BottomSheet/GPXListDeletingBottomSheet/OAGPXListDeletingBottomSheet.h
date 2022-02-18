//
//  OAGPXListDeletingBottomSheet.h
//  OsmAnd Maps
//
//  Created by nnngrach on 15.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@protocol OAGPXListDeletingBottomSheetDelegate <NSObject>

- (void) onDeleteConfirmed;

@end

@interface OAGPXListDeletingBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic, weak) id<OAGPXListDeletingBottomSheetDelegate> delegate;
@property (nonatomic) NSInteger deletingTracksCount;

@end
