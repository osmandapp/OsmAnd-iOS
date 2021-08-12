//
//  OAImportGPXBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 23/11/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"

@interface OAImportGPXBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@protocol OAGPXImportDelegate <NSObject>

@required
- (void) importAllGPXFromDocuments;

@end

@interface OAImportGPXBottomSheetViewController : OABottomSheetViewController

@property (nonatomic, readonly) id<OAGPXImportDelegate> gpxImportDelegate;

- (instancetype) initWithDelegate:(id<OAGPXImportDelegate>)gpxImportDelegate;

@end

