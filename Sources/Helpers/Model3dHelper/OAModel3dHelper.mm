//
//  OAModel3dHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 24/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAModel3dHelper.h"
#import "OAModel3dHelper+cpp.h"

@implementation OAModel3dWrapper

- (instancetype)initWith:(std::shared_ptr<const OsmAnd::Model3D>)model;
{
    self = [super init];
    if (self)
    {
        self.model = model;
    }
    return self;
}

@end


@implementation OALoad3dModelTask
{
    NSString *_modelDirPath;
    BOOL (^_callback)(OAModel3dWrapper *);
}

- (instancetype)initWith:(NSString *)modelDirPath callback:(BOOL (^)(OAModel3dWrapper *))callback
{
    self = [super init];
    if (self) 
    {
        _modelDirPath = modelDirPath;
        _callback = callback;
    }
    return self;
}

- (void) execute
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OAModel3dWrapper *result = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:result];
        });
    });
}

- (OAModel3dWrapper *) doInBackground
{
    // TODO: delete  storage/emulated/0/Android/data/net.osmand.plus/files/models/map_default_location/map_default_location.obj
    QString objFilePath = QString::fromNSString([NSString stringWithFormat:@"%@/%@.obj", _modelDirPath, _modelDirPath.lastPathComponent]);
    
    // TODO: delete  storage/emulated/0/Android/data/net.osmand.plus/files/models/map_default_location
    QString mtlFilePath = QString::fromNSString(_modelDirPath);
    
    const auto parser = OsmAnd::ObjParser(objFilePath, mtlFilePath);
    std::shared_ptr<const OsmAnd::Model3D> model = parser.parse();
    return [[OAModel3dWrapper alloc] initWith:model];
}

- (void) onPostExecute:(OAModel3dWrapper *)result
{
    if (_callback)
        _callback(result);
}

@end
