//
//  OARenderedObject+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 20/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#include <OsmAndCore.h>
#include <OsmAndCore/PointsAndAreas.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/IMapRenderer.h>

@interface OARenderedObject(cpp)

- (QVector<OsmAnd::PointI>) points;

+ (OARenderedObject *) parse:(std::shared_ptr<const OsmAnd::MapObject>)mapObject symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo;

@end
