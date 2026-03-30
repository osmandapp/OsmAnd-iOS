#import "OAAmenitySearcher+MapLayer.h"
#import "OAAmenitySearcher+cpp.h"
#import "OAPOIMapLayerData.h"
#import "OAPOIUIFilter+MapLayer.h"
#import "OAPOIBaseType.h"
#import "OAPOICategory.h"
#import "OsmAndApp.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Data/ObfInfo.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/AmenitiesInAreaSearch.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <atomic>

@implementation OAAmenitySearcher (MapLayer)

+ (NSArray<OAPOIMapLayerItem *> *)searchMapLayerOfflineItems:(OAPOIUIFilter *)filter
                                                 topLatitude:(double)topLatitude
                                              bottomLatitude:(double)bottomLatitude
                                               leftLongitude:(double)leftLongitude
                                              rightLongitude:(double)rightLongitude
                                                        zoom:(NSInteger)zoom
                                            maxAcceptedCount:(NSUInteger)maxAcceptedCount
                                               includeTravel:(BOOL)includeTravel
                                                 interrupted:(BOOL(^)(void))interrupted
{
    if (!filter || filter.isEmpty)
        return @[];

    const CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;

    const auto acceptedItemsCount = std::make_shared<std::atomic<NSUInteger>>(0);
    const auto stopAfterEnoughItems = std::make_shared<std::atomic<bool>>(false);

    std::shared_ptr<const OsmAnd::IQueryController> ctrl;
    ctrl.reset(new OsmAnd::FunctorQueryController([&interrupted, stopAfterEnoughItems]
                                                  (const OsmAnd::FunctorQueryController* const)
                                                  {
                                                      return stopAfterEnoughItems->load(std::memory_order_relaxed)
                                                          || (interrupted && interrupted());
                                                  }));

    const auto searchCriteria = std::make_shared<OsmAnd::AmenitiesInAreaSearch::Criteria>();
    OsmAnd::PointI topLeftPoint31 =
        OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLatitude, leftLongitude));
    OsmAnd::PointI bottomRightPoint31 =
        OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomLatitude, rightLongitude));
    const OsmAnd::AreaI bbox31(topLeftPoint31, bottomRightPoint31);
    searchCriteria->bbox31 = bbox31;
    searchCriteria->obfInfoAreaFilter = bbox31;

    auto categoriesFilter = QHash<QString, QStringList>();
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *types = [filter getAcceptedTypes];
    BOOL requiresTravelResources = filter.isTopWikiFilter;
    for (OAPOICategory *category in types.keyEnumerator)
    {
        NSString *categoryName = category.name;
        if ([categoryName isEqualToString:@"travel"] || [categoryName isEqualToString:@"routes"])
            requiresTravelResources = YES;

        QStringList list = QStringList();
        NSSet<NSString *> *subcategories = [types objectForKey:category];
        if (subcategories != [OAPOIBaseType nullSet])
        {
            for (NSString *sub in subcategories)
                list << QString::fromNSString(sub);
        }
        categoriesFilter.insert(QString::fromNSString(category.name), list);
    }
    if (categoriesFilter.size() > 0)
        searchCriteria->categoriesFilter = categoriesFilter;

    const auto desiredDataTypes = OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI);
    QList<std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource>> localResources;
    QList<std::shared_ptr<const OsmAnd::ResourcesManager::LocalResource>> fallbackBasemapResources;
    const auto allLocalResources = app.resourcesManager->getLocalResources();
    for (const auto& resource : allLocalResources)
    {
        const bool allowedType = resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion
            || (includeTravel && requiresTravelResources && resource->type == OsmAnd::ResourcesManager::ResourceType::Travel);
        if (!allowedType)
            continue;

        const auto obfMetadata = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(resource->metadata);
        if (!obfMetadata || !obfMetadata->obfFile || !obfMetadata->obfFile->obfInfo)
            continue;

        if (!obfMetadata->obfFile->obfInfo->containsDataFor(&bbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, desiredDataTypes))
            continue;

        const bool isBasemap = obfMetadata->obfFile->obfInfo->isBasemap
            || obfMetadata->obfFile->obfInfo->isBasemapWithCoastlines
            || obfMetadata->obfFile->filePath.toLower().contains(QStringLiteral("/world_"));
        if (isBasemap)
            fallbackBasemapResources.push_back(resource);
        else
            localResources.push_back(resource);
    }
    if (localResources.isEmpty())
        localResources = fallbackBasemapResources;
    searchCriteria->localResources = localResources;

    NSInteger samplingZoom = NSNotFound;
    if (!filter.isTopWikiFilter && zoom >= OsmAnd::MinZoomLevel && zoom <= 12)
    {
        samplingZoom = MIN(15, zoom + 3);
        searchCriteria->zoomFilter = (OsmAnd::ZoomLevel) samplingZoom;
    }

    NSMutableArray<OAPOIMapLayerItem *> *items = [NSMutableArray array];
    NSMutableSet<NSString *> *deduplicateTypeIdSet = [NSMutableSet set];

    const auto search = std::make_shared<OsmAnd::AmenitiesInAreaSearch>(obfsCollection);
    search->performSearch(*searchCriteria,
                          [filter, &items, &deduplicateTypeIdSet, maxAcceptedCount, acceptedItemsCount, stopAfterEnoughItems]
                          (const OsmAnd::ISearch::Criteria&, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              const auto& amenityResult = static_cast<const OsmAnd::AmenitiesInAreaSearch::ResultEntry&>(resultEntry);
                              const auto amenity = amenityResult.amenity;
                              OAPOIType *type = [OAAmenitySearcher parsePOITypeByAmenity:amenity];
                              if (![filter oa_acceptAmenity:amenity type:type])
                                  return;

                              NSString *typeIdKey = [OAAmenitySearcher getAmenityTypeIdKey:amenity];
                              if ([deduplicateTypeIdSet containsObject:typeIdKey])
                                  return;

                              [deduplicateTypeIdSet addObject:typeIdKey];
                              [items addObject:[[OAPOIMapLayerItem alloc] initWithAmenity:amenity]];

                              if (maxAcceptedCount > 0)
                              {
                                  const NSUInteger acceptedCount = acceptedItemsCount->fetch_add(1, std::memory_order_relaxed) + 1;
                                  if (acceptedCount >= maxAcceptedCount)
                                      stopAfterEnoughItems->store(true, std::memory_order_relaxed);
                              }
                          },
                          ctrl);

    const CFAbsoluteTime elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0;
    NSLog(@"[OAPOIMapLayer] searchMapLayerOfflineItems filter=%@ zoom=%ld samplingZoom=%@ resources=%d maxAccepted=%lu stopped=%@ items=%lu elapsed=%.1f ms",
          filter.filterId ?: @"",
          (long) zoom,
          samplingZoom == NSNotFound ? @"-" : [NSString stringWithFormat:@"%ld", (long) samplingZoom],
          localResources.size(),
          (unsigned long) maxAcceptedCount,
          stopAfterEnoughItems->load(std::memory_order_relaxed) ? @"YES" : @"NO",
          (unsigned long) items.count,
          elapsedMs);

    return [items copy];
}

@end
