//
//  OASelectTrackFolderViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OASTrackItem;

NS_ASSUME_NONNULL_BEGIN

@protocol OASelectTrackFolderDelegate <NSObject>

- (void) onFolderSelected:(nullable NSString *)selectedFolderName;
- (void) onFolderAdded:(NSString *)addedFolderName;

@optional
- (void) onFolderSelectCancelled;

@end

@interface OASelectTrackFolderViewController : OABaseNavbarViewController

@property (nonatomic, weak, nullable) id<OASelectTrackFolderDelegate> delegate;

@property (nonatomic, copy, nullable) NSString *suggestedFolderName;

- (nullable instancetype) initWithGPX:(OASTrackItem *)gpx;
- (nullable instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName;
- (nullable instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName excludedSubfolderPath:(NSString *)excludedSubfolderPath;
- (nullable instancetype) initWithSelectedFolderName:(NSString *)selectedFolderName excludedSubfolderPaths:(NSArray<NSString *> *)excludedSubfolderPaths;

@end

NS_ASSUME_NONNULL_END
