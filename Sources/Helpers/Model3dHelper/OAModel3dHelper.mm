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

#include <OsmAndCore/ObjParser.h>
#include "OsmAndCore/Map/Model3D.h"

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

- (void) setMainColor:(UIColor *)color
{
    _model->mainColor = [color toFColorARGB];
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
    NSString *documentsPath = OsmAndApp.instance.documentsPath;
    NSString *name = _modelDirPath.lastPathComponent;
    
    // .../Documents/models/map_default_location/map_default_location.obj
    QString objFilePath = QString::fromNSString([NSString stringWithFormat:@"%@/%@/%@/%@.obj", documentsPath, MODEL_3D_DIR, name, name]);
    
    // .../Documents/models/map_default_location
    QString mtlFilePath = QString::fromNSString([NSString stringWithFormat:@"%@/%@/%@", documentsPath, MODEL_3D_DIR, name]);
    
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
