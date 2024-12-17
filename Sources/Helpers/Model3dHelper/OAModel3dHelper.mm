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
#import "OsmAnd_Maps-Swift.h"

@implementation OAModel3dWrapper
{
    std::shared_ptr<OsmAnd::Model3D> _model;
    UIColor *_color;
}

- (instancetype)initWith:(std::shared_ptr<const OsmAnd::Model3D>)model;
{
    self = [super init];
    if (self)
    {
        _model = std::make_shared<OsmAnd::Model3D>(model->vertices, model->materials, model->bbox, model->mainColor);
    }
    return self;
}

- (std::shared_ptr<const OsmAnd::Model3D>) model
{
    return std::const_pointer_cast<const OsmAnd::Model3D>(_model);
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
        if (_callback)
            _callback(result);
    });
}

- (OAModel3dWrapper *) doInBackground
{
    // .../Documents/models/map_default_location/map_default_location.obj
    QString objFilePath = QString::fromNSString([Model3dHelper getModelObjFilePathWithDirPath:_modelDirPath]);
    // .../Documents/models/map_default_location
    QString mtlFilePath = QString::fromNSString(_modelDirPath);
    
    const auto parser = OsmAnd::ObjParser(objFilePath, mtlFilePath);
    std::shared_ptr<const OsmAnd::Model3D> model = parser.parse();
    if (!model)
    {
        NSLog(@"[ERROR] -> OALoad3dModelTask -> failed to parse model from mtlFilePath: %@ | objFilePath: %@", mtlFilePath.toNSString(), objFilePath.toNSString());
        return nil;
    }
    
    return [[OAModel3dWrapper alloc] initWith:model];
}

@end
