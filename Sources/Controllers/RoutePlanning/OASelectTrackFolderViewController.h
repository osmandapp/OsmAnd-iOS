//
//  OASelectTrackFolderViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"
#import "OAGPXDatabase.h"

@protocol OASelectTrackFolderDelegate <NSObject>

- (void) onFolderSelected:(NSString *)selectedFolderName;
- (void) onFolderAdded:(NSString *)addedFolderName;

@optional
- (void) onFolderSelectCancelled;

@end

@interface OASelectTrackFolderViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OASelectTrackFolderDelegate> delegate;

- (instancetype) initWithGPX:(OAGPX *)gpx;
- (instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName;
- (instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName hidingSubfolderPath:(NSString*)hidingSubfolderPath;

@end
