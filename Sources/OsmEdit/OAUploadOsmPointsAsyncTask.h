//
//  OAUploadOsmPointsAsyncTask.h
//  OsmAnd
//
//  Created by Paul on 6/26/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAOsmEditingViewController.h"

@class OAOsmEditingPlugin;
@class OAOsmPoint;

@protocol OAUploadTaskDelegate <NSObject>

- (void) uploadDidProgress:(float)progress;
- (void) uploadDidFinishWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads;
- (void) uploadDidCompleteWithSuccess:(BOOL)success;

@end

@interface OAUploadOsmPointsAsyncTask : NSObject

@property (nonatomic, weak) id<OAUploadTaskDelegate> delegate;
@property (nonatomic, readonly) BOOL requiresNoteUploadConfirmation;

- (id) initWithPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray<OAOsmPoint *> *)points closeChangeset:(BOOL)closeChangeset anonymous:(BOOL)anonymous comment:(NSString *)comment;

- (void)uploadPoints;

- (void)retryFailedPoints;
- (void)retryFailedPointsAllowingUnconfirmedNotes:(BOOL)allowUnconfirmedNotes;

- (void) setInterrupted:(BOOL)interrupted;

@end
