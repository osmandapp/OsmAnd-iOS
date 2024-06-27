//
//  OAModel3dHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 24/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAModel3dWrapper : NSObject

//@property (nonatomic) id obj;
//- (instancetype)initWith:(id)obj;

@end


@interface OALoad3dModelTask : NSObject

- (instancetype)initWith:(NSString *)modelDirPath callback:(BOOL (^)(OAModel3dWrapper *))callback;
- (void) execute;

@end
