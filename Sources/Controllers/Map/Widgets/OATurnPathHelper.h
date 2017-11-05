//
//  OATurnPathHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <turnType.h>

@interface OATurnPathHelper : NSObject

+ (void) calcTurnPath:(UIBezierPath *)pathForTurn outlay:(UIBezierPath *)outlay turnType:(std::shared_ptr<TurnType>)turnType transform:(CGAffineTransform)transform center:(CGPoint *)center mini:(BOOL)mini;

@end
