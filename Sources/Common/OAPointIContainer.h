//
//  OAPointIContainer.h
//  OsmAnd
//
//  Created by Alexey on 24.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ignore_warnings_on_external_includes.h>
#include <QVector>
#include <OsmAndCore/restore_internal_warnings.h>

#include <OsmAndCore.h>
#include <OsmAndCore/PointsAndAreas.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAPointIContainer : NSObject

@property (nonatomic, assign) std::vector<OsmAnd::PointI> points;
@property (nonatomic, assign) QVector<OsmAnd::PointI> qPoints;


@end

NS_ASSUME_NONNULL_END
