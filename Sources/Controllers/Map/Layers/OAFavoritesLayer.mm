//
//  OAFavoritesLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAFavoritesLayer.h"
#import "OADefaultFavorite.h"
#import "OAFavoriteItem.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAFavoritesMapLayerProvider.h"
#import "OAFavoritesHelper.h"
#import "OATargetInfoViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@implementation OAFavoritesLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _favoritesMarkersCollection;
    std::shared_ptr<OAFavoritesMapLayerProvider> _favoritesMapProvider;
    BOOL _showCaptionsCache;
    OsmAnd::PointI _hiddenPointPos31;
}

- (NSString *) layerId
{
    return kFavoritesLayerId;
}

- (void) initLayer
{
    [super initLayer];
 
    _hiddenPointPos31 = OsmAnd::PointI();
    _showCaptionsCache = self.showCaptions;
    
    self.app.favoritesCollection->collectionChangeObservable.attach((__bridge const void*)self,
                                                                [self]
                                                                (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                                {
                                                                    [self onFavoritesCollectionChanged];
                                                                });
    
    self.app.favoritesCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
                                                                      [self]
                                                                      (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                       const std::shared_ptr<const OsmAnd::IFavoriteLocation> favoriteLocation)
                                                                      {
                                                                          [self onFavoriteLocationChanged:favoriteLocation];
                                                                      });
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                    Visibility:self.isVisible];
}

- (BOOL) updateLayer
{
    [super updateLayer];
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:self.isVisible];

    if (self.showCaptions != _showCaptionsCache)
    {
        _showCaptionsCache = self.showCaptions;
        if (self.isVisible)
            [self reloadFavorites];
    }
    
    return YES;
}


- (BOOL) isVisible
{
    return [OAAppSettings.sharedManager.mapSettingShowFavorites get];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    self.app.favoritesCollection->collectionChangeObservable.detach((__bridge const void*)self);
    self.app.favoritesCollection->favoriteLocationChangeObservable.detach((__bridge const void*)self);
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        if (_favoritesMapProvider)
        {
            [self.mapView removeTiledSymbolsProvider:_favoritesMapProvider];
            _favoritesMapProvider = nullptr;
        }
        const auto rasterTileSize = self.mapViewController.referenceTileSizeRasterOrigInPixels;
        QList<OsmAnd::PointI> hiddenPoints;
        if (_hiddenPointPos31 != OsmAnd::PointI())
            hiddenPoints.append(_hiddenPointPos31);
        
        _favoritesMapProvider.reset(new OAFavoritesMapLayerProvider(self.app.favoritesCollection->getFavoriteLocations(),
                                                                    self.baseOrder, hiddenPoints, self.showCaptions, self.captionStyle, self.captionTopSpace, rasterTileSize));
        [self.mapView addTiledSymbolsProvider:_favoritesMapProvider];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeTiledSymbolsProvider:_favoritesMapProvider];
        _favoritesMapProvider = nullptr;
    }];
}

- (void) onFavoritesCollectionChanged
{
    [self reloadFavorites];
}

- (void) onFavoriteLocationChanged:(const std::shared_ptr<const OsmAnd::IFavoriteLocation>)favoriteLocation
{
    [self reloadFavorites];
}

- (void) reloadFavorites
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self show];
    });
}

- (UIImage *) getFavoriteImage:(const OsmAnd::IFavoriteLocation *)fav
{
    UIColor* color = [UIColor colorWithRed:fav->getColor().r/255.0 green:fav->getColor().g/255.0 blue:fav->getColor().b/255.0 alpha:1.0];
    return [self.class getImageWithColor:color
                        background:fav->getBackground().toNSString()
                              icon:[@"mx_" stringByAppendingString:fav->getIcon().toNSString()]];
}

+ (UIImage *) getImageWithColor:(UIColor *)color background:(NSString *)background icon:(NSString *)icon
{
    UIImage *shadowImage = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"ic_bg_point_%@_bottom", background]];
    if (!shadowImage)
        shadowImage = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"circle"] color:color];
    
    UIImage *colorFilledImage = [OAUtilities tintImageWithColor:[UIImage imageNamed:[NSString stringWithFormat:@"ic_bg_point_%@_center", background]] color:color];
    if (!colorFilledImage)
        colorFilledImage = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"circle"] color:color];
    
    UIImage *innerImage = [OAUtilities tintImageWithColor:[OATargetInfoViewController getIcon:icon] color:UIColor.whiteColor];
    if (!innerImage)
        innerImage = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"mx_special_star"] color:UIColor.whiteColor];
    
    UIImage *topImage = [OATargetInfoViewController getIcon:[NSString stringWithFormat:@"ic_bg_point_%@_top", background]];
    if (!topImage)
        topImage = [OATargetInfoViewController getIcon:@"mx_special_star"];
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat outerImageSide = 36 * scale;
    CGFloat innerImageSide = 27. / 2 * scale;
    CGRect outerImageRect = CGRectMake(0, 0, outerImageSide, outerImageSide);
    CGRect innerImageCenterRect = CGRectMake(((outerImageSide / 2) - (innerImageSide / 2)), ((outerImageSide / 2) - (innerImageSide / 2)), innerImageSide, innerImageSide);
    
    UIGraphicsBeginImageContext(outerImageRect.size);
    [shadowImage drawInRect:outerImageRect];
    [colorFilledImage drawInRect:outerImageRect];
    [innerImage drawInRect:innerImageCenterRect blendMode:kCGBlendModeNormal alpha:1.0];
    [topImage drawInRect:outerImageRect];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return finalImage;
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    if (const auto favLoc = reinterpret_cast<const OsmAnd::IFavoriteLocation *>(obj))
    {
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetFavorite;
        double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
        double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
        targetPoint.location = CLLocationCoordinate2DMake(favLat, favLon);
      
        
        if (![OAFavoritesHelper isFavoritesLoaded])
            [OAFavoritesHelper loadFavorites];
        
        OAFavoriteItem *storedItem = [OAFavoritesHelper getVisibleFavByLat:favLat lon:favLon];
        targetPoint.title = storedItem ? [storedItem getDisplayName] : favLoc->getTitle().toNSString();
        if (storedItem && storedItem.specialPointType == [OASpecialPointType PARKING])
            targetPoint.type = OATargetParking;
        
        targetPoint.icon = [self getFavoriteImage:favLoc];
        
        OAFavoriteItem *item;
        for (const auto& favLocPtr : self.app.favoritesCollection->getFavoriteLocations())
        {
            if (favLoc->isEqual(favLocPtr.get()))
            {
                item = [[OAFavoriteItem alloc] initWithFavorite:favLocPtr];
                targetPoint.targetObj = item;
                break;
            }
        }
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    else
    {
        return nil;
    }
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    if (self.isVisible)
    {
        if (const auto mapSymbol = dynamic_pointer_cast<const OsmAnd::IBillboardMapSymbol>(symbolInfo->mapSymbol))
        {
            const auto symbolPos31 = mapSymbol->getPosition31();
            for (const auto& favLoc : self.app.favoritesCollection->getFavoriteLocations())
            {
                if (favLoc->getPosition31() == symbolPos31)
                {
                    OATargetPoint *targetPoint = [self getTargetPointCpp:favLoc.get()];
                    if (![found containsObject:targetPoint])
                        [found addObject:targetPoint];
                }
            }
        }
    }
}

#pragma mark - OAMoveObjectProvider

- (BOOL) isObjectMovable:(id)object
{
    return [object isKindOfClass:OAFavoriteItem.class];
}

- (void) applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OAFavoriteItem *item = (OAFavoriteItem *)object;
        _hiddenPointPos31 = OsmAnd::PointI();
        const auto& favorite = item.favorite;
        if (favorite != nullptr)
        {
            QString elevation = favorite->getElevation();
            QString time = favorite->getTime();
            QString creationTime = favorite->getCreationTime();
            QString title = favorite->getTitle();
            QString description = favorite->getDescription();
            QString address = favorite->getAddress();
            QString group = favorite->getGroup();
            QString icon = favorite->getIcon();
            QString background = favorite->getBackground();
            OsmAnd::ColorRGB color = favorite->getColor();
            
            self.app.favoritesCollection->removeFavoriteLocation(favorite);
            self.app.favoritesCollection->createFavoriteLocation(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(position.latitude, position.longitude)),
                                                            elevation,
                                                            time,
                                                            creationTime,
                                                            title,
                                                            description,
                                                            address,
                                                            group,
                                                            icon,
                                                            background,
                                                            color);
            [self.app saveFavoritesToPermamentStorage];
        }
    }
}

- (UIImage *) getDefaultFavoriteImage
{
    OAFavoriteColor* color = OADefaultFavorite.builtinColors.firstObject;
    return [self.class getImageWithColor:color.color
                        background:@"circle"
                              icon:[@"mx_" stringByAppendingString:@"special_star"]];
}

- (UIImage *) getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        OAFavoriteItem *item = (OAFavoriteItem *)object;
        const auto favLoc = item.favorite;
        UIImage *img = [self getFavoriteImage:favLoc.get()];
        return [OAUtilities resizeImage:img newSize:CGSizeMake(60., 60.)];
    }
    return [self getDefaultFavoriteImage];
}

- (void) setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OAFavoriteItem *item = (OAFavoriteItem *)object;
        _hiddenPointPos31 = hidden ? item.favorite->getPosition31() : OsmAnd::PointI();
        [self reloadFavorites];
    }
}

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment
{
    return EOAPinAlignmentCenterVertical;
}


- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment
{
    return EOAPinAlignmentCenterHorizontal;
}

@end
