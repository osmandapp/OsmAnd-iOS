//
//  OAMap3DModeVisibilityType.h
//  OsmAnd
//
//  Created by nnngrach on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMap3DModeVisibilityType : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *iconName;

+ (OAMap3DModeVisibilityType *) HIDDEN;
+ (OAMap3DModeVisibilityType *) VISIBLE;
+ (OAMap3DModeVisibilityType *) VISIBLE_IN_3D_MODE;

+ (NSArray<OAMap3DModeVisibilityType *> *) getTypes;

@end
