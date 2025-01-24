//
//  OARenderedObject.m
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OARenderedObject.h"
#import "OARenderedObject+cpp.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"

#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/Utilities.h>

@implementation OARenderedObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tags = [MutableOrderedDictionary new];
    }
    return self;
}

- (void) setBBox:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    _bboxLeft = left;
    _bboxTop = top;
    _bboxRight = right;
    _bboxBottom = bottom;
}


- (BOOL) isText
{
    return self.name && self.name.length > 0;
}

+ (OARenderedObject *) parse:(std::shared_ptr<const OsmAnd::MapObject>)mapObject symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo
{
    OARenderedObject *renderedObject = [OARenderedObject new];
    if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(mapObject))
    {
        
        renderedObject.obfId = obfMapObject->id;
        
        for (const OsmAnd::PointI pointI : obfMapObject->points31)
        {
            [renderedObject addLocation:pointI.x y:pointI.y];
        }
        double lat = OsmAnd::Utilities::get31LatitudeY(obfMapObject->getLabelCoordinateY());
        double lon = OsmAnd::Utilities::get31LongitudeX(obfMapObject->getLabelCoordinateX());
        [renderedObject setLabelLatLon:CLLocationCoordinate2DMake(lat, lon)];
        
        if (symbolInfo)
        {
            if (symbolInfo->mapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Caption)
            {
                if (const auto billboardRasterMapSymbol = std::static_pointer_cast<const OsmAnd::BillboardRasterMapSymbol>(symbolInfo->mapSymbol))
                    renderedObject.name = billboardRasterMapSymbol->content.toNSString();
            }
            
            if (symbolInfo->mapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Icon)
            {
                if (const auto billboardRasterMapSymbol = std::static_pointer_cast<const OsmAnd::BillboardRasterMapSymbol>(symbolInfo->mapSymbol))
                    renderedObject.iconRes = billboardRasterMapSymbol->content.toNSString();
            }
        }
        
        NSMutableDictionary *names = [NSMutableDictionary dictionary];
        NSString *nameLocalized = [OAPOIHelper processLocalizedNames:obfMapObject->getCaptionsInAllLanguages() nativeName:obfMapObject->getCaptionInNativeLanguage() names:names];
        if (nameLocalized && nameLocalized.length > 0)
            renderedObject.name = nameLocalized;
        if (!renderedObject.name)
            renderedObject.name = obfMapObject->getCaptionInNativeLanguage().toNSString();
        renderedObject.nameLocalized = renderedObject.name;
        renderedObject.localizedNames = names;
        
        MutableOrderedDictionary<NSString *, NSString *> *parsedTags = [MutableOrderedDictionary new];
        const auto tags = obfMapObject->getResolvedAttributes();
        for (auto i = tags.begin(); i != tags.end(); ++i)
        {
            NSString *key = i.key().toNSString();
            NSString *value = i.value().toNSString();
            parsedTags[key] = value;
        }
        renderedObject.tags = parsedTags;
    }
    
    return renderedObject;
}

- (long) estimatedArea
{
    return abs(_bboxRight - _bboxLeft) * abs(_bboxTop - _bboxBottom);
}

@end
