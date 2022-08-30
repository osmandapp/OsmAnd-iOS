//
//  OADeleteFilesCommand.m
//  OsmAnd Maps
//
//  Created by Paul on 13.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OADeleteFilesCommand.h"
#import "OARemoteFile.h"

@implementation OADeleteFilesCommand
{
    NSArray<OARemoteFile *> *_remoteFiles;
}

- (instancetype) initWithVersion:(BOOL)byVersion listener:(id<OAOnDeleteFilesListener>)listener remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles
{
    self = [super initWithVersion:byVersion listener:listener];
    if (self)
    {
        _remoteFiles = remoteFiles;
    }
    return self;
}

- (void) onPreExecute
{
    [super onPreExecute];
    for (id<OAOnDeleteFilesListener> listener in [self getListeners])
        [listener onFilesDeleteStarted:_remoteFiles];
}

- (void) doInBackground
{
    [self deleteFiles:_remoteFiles];
}

@end
