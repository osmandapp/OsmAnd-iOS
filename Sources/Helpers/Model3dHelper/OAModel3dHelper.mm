//
//  OAModel3dHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 24/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAModel3dHelper.h"
#import "OAModel3dHelper+cpp.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"
#import "OAIndexConstants.h"

@implementation OAModel3dWrapper
{
    OsmAnd::Model3D *_model;
}

- (instancetype)initWith:(std::shared_ptr<const OsmAnd::Model3D>)model;
{
    self = [super init];
    if (self)
    {
        _model = new OsmAnd::Model3D(model->vertices, model->materials, model->bbox);
    }
    return self;
}

- (std::shared_ptr<const OsmAnd::Model3D>) model
{
    return std::shared_ptr<const OsmAnd::Model3D>(new OsmAnd::Model3D(_model->vertices, _model->materials, _model->bbox, _model->mainColor));
}

- (void) setMainColor:(UIColor *)color
{
    _model->mainColor = [color toFColorARGB];
}

@end


@implementation OALoad3dModelTask
{
    BOOL (^_callback)(OAModel3dWrapper *);
}

- (instancetype)initWith:(NSString *)modelDirName callback:(BOOL (^)(OAModel3dWrapper *))callback
{
    self = [super init];
    if (self) 
    {
        _modelDirPath = [[OsmAndApp.instance.documentsPath stringByAppendingPathComponent:MODEL_3D_DIR] stringByAppendingPathComponent:modelDirName];
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
    NSString *name = _modelDirPath.lastPathComponent;
    
    // .../Documents/models/map_default_location/map_default_location.obj
    QString objFilePath = QString::fromNSString([NSString stringWithFormat:@"%@/%@.obj", _modelDirPath, name]);
    
    // .../Documents/models/map_default_location
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
