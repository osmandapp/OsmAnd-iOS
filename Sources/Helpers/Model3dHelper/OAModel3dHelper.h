//
//  OAModel3dHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 24/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAModel3dWrapper : NSObject

- (void) setMainColor:(UIColor *)color;

@end


@interface OALoad3dModelTask : NSObject

@property (nonatomic) NSString *modelDirPath;

- (instancetype)initWith:(NSString *)modelDirPath callback:(BOOL (^)(OAModel3dWrapper *))callback;
- (void) execute;

@end
