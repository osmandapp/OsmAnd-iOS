//
//  OATargetInfoViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

// analog in android: MenuBuilder.java

#import "OATargetInfoViewController.h"
#import "OsmAndApp.h"
#import "OANativeUtilities.h"
#import "OATargetInfoViewCell.h"
#import "OATargetInfoCollapsableViewCell.h"
#import "OATargetInfoCollapsableCoordinatesViewCell.h"
#import "OAWebViewCell.h"
#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OAAmenitySearcher.h"
#import "OAAmenitySearcher+cpp.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OALocationServices.h"
#import "OAPOICategory.h"
#import "OATransportStop.h"
#import "OACollapsableNearestPoiWikiView.h"
#import "OATransportStopRoute.h"
#import "OACollapsableTransportStopRoutesView.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OAPointDescription.h"
#import "OACollapsableCoordinatesView.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAPluginPopupViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAColors.h"
#import "OAPOIFiltersHelper.h"
#import "OAMapUtils.h"
#import "OAWikiImageHelper.h"
#import "OAWikipediaPlugin.h"
#import "OAOsmAndFormatter.h"
#import "OASimpleTableViewCell.h"
#import "OAMapillaryOsmTagHelper.h"
#import "OACollapsableWaypointsView.h"
#import "OATextMultilineTableViewCell.h"
#import "OAEditDescriptionViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OACollapsableView.h"
#import "OAMapRendererEnvironment.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OrderedDictionary.h"
#import "OARenderedObject.h"
#import "OARenderedObject+cpp.h"

#include <OsmAndCore/Utilities.h>

// Links
static NSString *kWikiLink = @".wikipedia.org/w";
static NSString *kWhatsAppLink = @"https://wa.me/%@";
static NSString *kViberLink = @"viber://contact?number=%@";
static NSString *kSkypeLink = @"skype:%@";
static NSString *kMailLink = @"mailto:%@";
static NSString *kInstagramLink = @"https://www.instagram.com/%@";
static NSString *kFacebookLink = @"https://www.facebook.com/%@";

NSString * const TYPE_MAPILLARY_PHOTO = @"mapillary-photo";
NSString * const TYPE_MAPILLARY_CONTRIBUTE = @"mapillary-contribute";
NSString * const TYPE_MAPILLARY_EMPTY = @"mapillary-empty";
NSString * const TYPE_URL_PHOTO = @"url-photo";
NSString * const TYPE_WIKIMEDIA_PHOTO = @"wikimedia-photo";
NSString * const TYPE_WIKIDATA_PHOTO = @"wikidata-photo";

static NSString *WITHIN_POLYGONS_ROW_KEY = @"within_polygons";

// HTML for ViewPort
static NSString *const kViewPortHtml = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>";

// Constants for Nearby POI
static const NSInteger kNearbyPoiMaxCount = 10;
static const NSInteger kNearbyPoiMinRadius = 250;
static const NSInteger kNearbyPoiMaxRadius = 1000;
static const NSInteger kNearbyPoiSearchFactory = 2;

static const CGFloat kBackButtonOffsetLeftFromFrame = 6.0;

static const CGFloat kTextMaxHeight = 150.0;

static const NSInteger kTitleLimit = 60;

static const NSInteger kOrderShortDescrRow = -10000;
static const NSInteger kOrderPhotoRow = -103;
static const NSInteger kOrderMapillaryRow = -102;
static const NSInteger kOrderWithinRow = -101;
static const NSInteger kOrderTravelGuides = -100;
static const NSInteger kOrderTopInternalRow = 0;
static const NSInteger kOrderDescriptionRow = 0;
static const NSInteger kOrderInternalRow = 0;
static const NSInteger kOrderDetailsRow = 0;
static const NSInteger kOrderTitleRow = 0;
static const NSInteger kOrderDateRow = 3;
static const NSInteger kOrderCoommentRow = 4;
static const NSInteger kOrderNearestRow = 1000;
static const NSInteger kOrderNamesRow = 18000;
static const NSInteger kOrderOsmRow = 19000;
static const NSInteger kOrderCoordinatesRow = 20000;
static const NSInteger kOrderPhotoEmptyRow = 30001;
static const NSInteger kOrderMapillaryEmptyRow = 30002;


@interface OATargetInfoViewController() <CollapsableCardViewDelegate, OAEditDescriptionViewControllerDelegate>

@property (nonatomic) BOOL wikiCardsReady;
@property (nonatomic, strong) NSURLSession *onlineAndMapillarySession; //TODO: move to plugin?

@end

@implementation OATargetInfoViewController
{
    NSMutableArray<OAAmenityInfoRow *> *_rows;
    CGFloat _contentHeight;
    UIColor *_contentColor;
    NSArray<OAPOI *> *_nearestWiki;
    NSArray<OAPOI *> *_nearestPoi;
    BOOL _hasOsmWiki;
    CGFloat _calculatedWidth;
    
    OAAmenityInfoRow *_onlinePhotoCardsRowInfo;
    OAAmenityInfoRow *_mapillaryCardsRowInfo;

    BOOL _otherCardsReady;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _showTitleIfTruncated = YES;
    }
    return self;
}

- (void) setInfoRows:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    _rows = rows;
}

- (void) appendInfoRow:(OAAmenityInfoRow *)row
{
    if (!_rows)
        _rows = [NSMutableArray new];
    
    [_rows addObject:row];
    
    [self sortInfoRows];
    _calculatedWidth = 0;
    [self contentHeight:self.tableView.bounds.size.width];
}

- (BOOL) needBuildCoordinatesRow
{
    return YES;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportsForceClose
{
    return YES;
}

- (BOOL)shouldEnterContextModeManually
{
    return YES;
}

+ (UIImage *) getIcon:(NSString *)fileName
{
    UIImage *img = nil;
    if ([fileName hasPrefix:@"mx_"])
        img = [UIImage mapSvgImageNamed:fileName];
    else
        img = [UIImage imageNamed:fileName];

    return img;
}

+ (UIImage *) getIcon:(NSString *)fileName size:(CGSize)size
{
    UIImage *img = nil;
    if ([fileName hasPrefix:@"mx_"])
        img = [UIImage mapSvgImageNamed:fileName width:size.width height:size.height];
    else
        img = [UIImage imageNamed:fileName];

    return img;
}

- (void) buildTopInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    [self buildMainImage:rows];
    [self buildDescription:rows];
    
    NSArray<OATransportStopRoute *> *localTransportRoutes = [self getLocalTransportStopRoutes];
    NSArray<OATransportStopRoute *> *nearbyTransportRoutes = [self getNearbyTransportStopRoutes];
    if (localTransportRoutes.count > 0)
    {
        OAAmenityInfoRow *rowInfo = [[OAAmenityInfoRow alloc] initWithKey:nil icon:nil textPrefix:nil text:OALocalizedString(@"transport_Routes") textColor:nil isText:NO needLinks:NO order:kOrderTopInternalRow typeName:@"" isPhoneNumber:NO isUrl:NO];
        rowInfo.collapsed = NO;
        rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
        ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = localTransportRoutes;
        [_rows addObject:rowInfo];
    }
    if (nearbyTransportRoutes.count > 0)
    {
        NSString *routesWithingDistance = [NSString stringWithFormat:@"%@ %@",  OALocalizedString(@"transport_nearby_routes_within"), [OAOsmAndFormatter getFormattedDistance:kShowStopsRadiusMeters]];
        OAAmenityInfoRow *rowInfo = [[OAAmenityInfoRow alloc] initWithKey:nil icon:nil textPrefix:nil text:routesWithingDistance textColor:nil isText:NO needLinks:NO order:kOrderTopInternalRow typeName:@"" isPhoneNumber:NO isUrl:NO];
        rowInfo.collapsed = NO;
        rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
        ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = nearbyTransportRoutes;
        [_rows addObject:rowInfo];
    }
}

- (void) buildMainImage:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    // implement in subclasses
}

- (void) buildDescription:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    // implement in subclasses
}

- (void) buildInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    // implement in subclasses
}

- (void) appdendDetailsButtonRow:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    if ([self showDetailsButton])
    {
        OAAmenityInfoRow *collapseDetailsRowCell = [[OAAmenityInfoRow alloc] initWithKey:nil icon:[OATargetInfoViewController getIcon:nil] textPrefix:nil text:@"" textColor:nil isText:NO needLinks:NO order:kOrderDetailsRow typeName:kCollapseDetailsRowType isPhoneNumber:NO isUrl:NO];
        [collapseDetailsRowCell setHeight:[self detailsButtonHeight]];
        [rows addObject:collapseDetailsRowCell];
    }
}

- (void) buildMenu:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    _rows = rows;
    
    // don't exist in android. and maybe already not used in ios.
    [self appdendDetailsButtonRow:_rows];

    [self buildTopInternal:_rows];

    if (_showTitleIfTruncated)
        [self buildTitleRow];
    
    [self buildWithinRow];
    [self buildNearestRows];
    
    // don't exist in android
    if (self.additionalRows)
        [_rows addObjectsFromArray:self.additionalRows];
    
    //    if (needBuildPlainMenuItems()) {
    //        buildPlainMenuItems(view);
    //    }
    
    [self buildInternal:_rows];
    
    [self buildPluginRows];

    if ([self needBuildCoordinatesRow])
        [self buildCoordinateRows:rows];
    
    if (!_customOnlinePhotosPosition)
        [self buildPhotosRow];
    
    [self sortInfoRows];
    _calculatedWidth = 0;
    [self contentHeight:self.tableView.bounds.size.width];
}

- (void) sortInfoRows
{
    [_rows sortUsingComparator:^NSComparisonResult(OAAmenityInfoRow *row1, OAAmenityInfoRow *row2) {
        if (row1.order < row2.order)
            return NSOrderedAscending;
        else if (row1.order == row2.order)
            return [row1.typeName localizedCompare:row2.typeName];
        else
            return NSOrderedDescending;
    }];
}

- (void)handleOnlineAndMapillaryLoadingIfNeeded {
    if (!_onlinePhotoCardsRowInfo.collapsed
        || (_mapillaryCardsRowInfo && !_mapillaryCardsRowInfo.collapsed))
    {
        _otherCardsReady = NO;
        _wikiCardsReady = NO;
        
        [_onlineAndMapillarySession invalidateAndCancel];
        _onlineAndMapillarySession = nil;
        
        [self startLoadingImages];
    }
}

- (void)buildTitleRow
{
    if (self.delegate)
    {
        NSString *title = [self.delegate getTargetTitle];
        if (title.length > kTitleLimit)
        {
            OAAmenityInfoRow *row = [[OAAmenityInfoRow alloc] initWithKey:@"title" icon:[UIImage templateImageNamed:@"ic_description"] textPrefix:nil text:title textColor:nil isText:YES needLinks:NO order:kOrderTitleRow typeName:@"title" isPhoneNumber:NO isUrl:NO];
            [_rows addObject:row];
        }
    }
}

- (void)buildWithinRow
{
    if (![[self getTargetObj] isKindOfClass:OAMapObject.class])
        return;
    
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    NSArray<OARenderedObject *> *polygons = [mapViewController.mapLayers.contextMenuLayer retrievePolygonsAroundMapObject:self.location.latitude lon:self.location.longitude mapObject:[self getTargetObj]];
    
    polygons = [polygons sortedArrayUsingComparator:^NSComparisonResult(OARenderedObject *obj1, OARenderedObject *obj2) {
        long area1 = [obj1 estimatedArea];
        long area2 = [obj2 estimatedArea];
        if (area1 > area2)
            return NSOrderedDescending;
        else if (area1 < area2)
            return NSOrderedAscending;
        return NSOrderedSame;
    }];
    
    if (polygons.count > 0)
    {
        NSString *title = OALocalizedString(@"transport_nearby_routes");
        
        NSMutableArray<NSString *> *names = [NSMutableArray new];
        for (OARenderedObject *polygon in polygons)
        {
            OAPOI *syntheticAmenity = [BaseDetailsObject convertRenderedObjectToAmenity:polygon];
            NSString *name = [OAUtilities capitalizeFirstLetter:[RenderedObjectHelper getFirstNonEmptyNameFor:syntheticAmenity withRenderedObject:polygon]];
            [names addObject:name];
        }
        NSString *rowSummary = [self getMenuObjectsNamesByComma:names];
        
        NSMutableArray *detailsArray = [self getWithinCollapsableContent:polygons];
        
        OAAmenityInfoRow *row = [[OAAmenityInfoRow alloc] initWithKey:WITHIN_POLYGONS_ROW_KEY
                                        icon:[UIImage templateImageNamed:@"ic_custom_pin_location"]
                                  textPrefix:title
                                        text:rowSummary
                                   textColor:nil
                                      isText:YES
                                   needLinks:YES
                                       order:kOrderWithinRow
                                    typeName:WITHIN_POLYGONS_ROW_KEY
                               isPhoneNumber:NO
                                       isUrl:NO];
        
        [row setDetailsArray:detailsArray];
        row.collapsed = YES;
        row.collapsableView = nil;
        [_rows addObject:row];
    }
}

- (NSMutableArray<NSDictionary<NSString *, NSString *> *> *) getWithinCollapsableContent:(NSArray<OARenderedObject *> *)renderedObjects
{
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *array = [NSMutableArray new];
    NSString *sectionHeader = OALocalizedString(@"transport_nearby_routes");
    
    for (int i = 0; i < renderedObjects.count; i++)
    {
        OARenderedObject *renderedObject = renderedObjects[i];
        OAPOI *syntheticAmenity = [BaseDetailsObject convertRenderedObjectToAmenity:renderedObject];

        NSString *key;
        NSString *translatedType = [RenderedObjectHelper getTranslatedTypeWithRenderedObject:renderedObject];
        NSString *value = [RenderedObjectHelper getFirstNonEmptyNameFor:syntheticAmenity withRenderedObject:renderedObject];

        if ([translatedType containsString:@":"] && (value.length == 0 || [translatedType isEqualToString:value]))
        {
            int firstCommaIndex = [translatedType indexOf:@":"];
            key = [translatedType substringToIndex:firstCommaIndex];
            value = [[[translatedType substringFromIndex:firstCommaIndex + 1] trim] capitalizedString];
        }
        else
        {
            key = translatedType.length > 0 ? translatedType : syntheticAmenity.type.nameLocalized;
            if (value.length == 0)
            {
                value = key;
                key = OALocalizedString(@"shared_string_location");
            }
            if ([[key lowercaseString] isEqualToString:[value lowercaseString]])
            {
                key = OALocalizedString(@"shared_string_location");
            }
        }
        
        [array addObject:@{
            @"key": [NSString stringWithFormat:@"within:%@:%@", key, value],
            @"value": value,
            @"localizedTitle": sectionHeader,
            @"renderedObject": renderedObject
        }];
    }
    return array;
}

- (NSString *) getMenuObjectsNamesByComma:(NSArray<NSString *> *)menuObjects
{
    return menuObjects.count == 0 ? @"" : [menuObjects componentsJoinedByString:@", "];
}

- (void)buildNearestRow:(BOOL)isWiki
{
    id targetObj = [self getTargetObj];
    if ([targetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = (OAPOI *) targetObj;
        OAPOIUIFilter *filter = [self getPoiFilterForType:poi isWiki:isWiki];
		if (!filter)
            return;
        
        if (isWiki)
            [self processNearestWiki:poi];
        else
            [self processNearestPoi:poi filter:filter];

        NSArray<OAPOI *> *nearest = isWiki ? _nearestWiki : _nearestPoi;
        NSString *rowText = isWiki ? [NSString stringWithFormat:@"%@ (%d)", OALocalizedString(@"wiki_around"), (int) nearest.count] : [NSString stringWithFormat:@"%@ \"%@\" (%d)", OALocalizedString(@"speak_poi"), poi.type.nameLocalized, (int) nearest.count];

        if (nearest.count > 0)
        {
            UIImage *icon = isWiki ? [UIImage mapSvgImageNamed:@"mx_wiki_place"] : poi.icon;
            OAAmenityInfoRow *rowInfo = [[OAAmenityInfoRow alloc] initWithKey:nil icon:icon textPrefix:nil text:rowText textColor:nil isText:NO needLinks:NO order:kOrderNearestRow typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsed = YES;
            rowInfo.collapsableView = [[OACollapsableNearestPoiWikiView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            [((OACollapsableNearestPoiWikiView *) rowInfo.collapsableView) setData:nearest hasItems:(isWiki ? _hasOsmWiki : YES) latitude:self.location.latitude longitude:self.location.longitude filter:filter];
            rowInfo.order = kOrderNearestRow;
            [_rows addObject:rowInfo];
        }
    }
}

- (void) buildDateRow:(NSMutableArray<OAAmenityInfoRow *> *)rows timestamp:(NSDate *)timestamp
{
    if (timestamp)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        NSString *formattedDate = [dateFormatter stringFromDate:timestamp];
        OAAmenityInfoRow *dateRowCell = [[OAAmenityInfoRow alloc] initWithKey:nil icon:[OATargetInfoViewController getIcon:@"ic_custom_date"] textPrefix:nil text:formattedDate textColor:nil isText:NO needLinks:NO order:kOrderDateRow typeName:kTimestampRowType isPhoneNumber:NO isUrl:NO];
        [rows addObject:dateRowCell];
    }
}

- (void) buildCommentRow:(NSMutableArray<OAAmenityInfoRow *> *)rows comment:(NSString *)comment
{
    if (comment.length > 0)
    {
        OAAmenityInfoRow *commentRow = [[OAAmenityInfoRow alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_description"] textPrefix:nil text:comment textColor:nil isText:YES needLinks:NO order:kOrderCoommentRow typeName:kCommentRowType isPhoneNumber:NO isUrl:NO];
        [rows addObject:commentRow];
    }
}

- (void)buildCoordinateRows:(NSMutableArray<OAAmenityInfoRow *> *)rows
{
    OAAmenityInfoRow *coordinatesRow = [[OAAmenityInfoRow alloc] initWithKey:nil icon:nil textPrefix:nil text:@"" textColor:nil isText:NO needLinks:NO order:kOrderCoordinatesRow typeName:@"" isPhoneNumber:NO isUrl:NO];
    coordinatesRow.collapsed = YES;
    OACollapsableCoordinatesView *collapsableView = [[OACollapsableCoordinatesView alloc] initWithFrame:CGRectMake(0, 0, 320, 100) lat:self.location.latitude lon:self.location.longitude];
    coordinatesRow.collapsableView = collapsableView;
    [rows addObject:coordinatesRow];
}

- (void)buildNearestRows
{
    [self buildNearestWikiRow];
    [self buildNearestPoiRow];
    [self buildRouteRows];
}

- (void)buildNearestWikiRow
{
    if ([self showNearestWiki] && !OAIAPHelper.sharedInstance.wiki.disabled && [OAPluginsHelper getEnabledPlugin:OAWikipediaPlugin.class])
        [self buildNearestRow:YES];
}

- (void)buildNearestPoiRow
{
    if ([self showNearestPoi])
        [self buildNearestRow:NO];
}

- (void)buildRouteRows
{
    // TODO: implement
}

- (void)buildPluginRows
{
    [self addOsmRowInfoIfNeeded];
    [self addMapillaryCardsRowInfoIfNeeded];
}

- (void) calculateRowsHeight:(CGFloat)width
{
    CGFloat regularTextWidth = width - kMarginLeft - kMarginRight;
    CGFloat collapsableTitleWidth = width - kMarginLeft - kCollapsableTitleMarginRight;
    for (OAAmenityInfoRow *row in _rows)
    {
        CGFloat textWidth = row.collapsable ? collapsableTitleWidth : regularTextWidth;
        CGFloat rowHeight;
        if ([row.typeName isEqualToString:kCollapseDetailsRowType])
            continue;
        if (row.isHtml)
        {
            rowHeight = 230.0;
            row.height = rowHeight;
            row.moreText = YES;
        }
        else
        {
            NSString *text = row.textPrefix.length == 0 ? row.text : [NSString stringWithFormat:@"%@: %@", row.textPrefix, row.text];
            CGSize fullBounds = [OAUtilities calculateTextBounds:text width:textWidth font:[row getFont]];
            CGSize bounds = [OAUtilities calculateTextBounds:text width:textWidth height:kTextMaxHeight font:[row getFont]];
            
            rowHeight = MAX(bounds.height, 28.0) + 11.0 + 11.0;
            row.height = rowHeight;
            row.moreText = fullBounds.height > bounds.height;
        }
        if (row.collapsable)
            [row.collapsableView adjustHeightForWidth:width];
    }
}

- (CGFloat) contentHeight
{
    return _contentHeight;
}

- (CGFloat) contentHeight:(CGFloat)width
{
    if (_calculatedWidth != width)
    {
        [self calculateRowsHeight:width];
        [self calculateContentHeight];
        _calculatedWidth = width;
    }
    return _contentHeight;
}

- (void) calculateContentHeight
{
    CGFloat h = 0;
    for (OAAmenityInfoRow *row in _rows)
        h += row.height;

    _contentHeight = h;
}

- (void)cancelPressed
{
    [self.delegate btnCancelPressed];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.tableView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    self.tableView.backgroundView = view;
    self.tableView.scrollEnabled = NO;
    _calculatedWidth = 0;
    [self buildMenu:[NSMutableArray array]];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakSelf.tableView reloadData];
    } completion:nil];
}

- (void)updateNavBarSubviewsLayout
{
    [super updateNavBarSubviewsLayout];
    [self adjustCancelButtonPosition];
    [self adjustTitleViewPosition];
}

- (void)adjustCancelButtonPosition
{
    CGRect buttonFrame = self.buttonCancel.frame;
    buttonFrame.origin.x = [OAUtilities isLandscape] ? kBackButtonOffsetLeftFromFrame + [OAUtilities getLeftMargin] : 0.0;
    self.buttonCancel.frame = buttonFrame;
}

- (void)adjustTitleViewPosition
{
    CGRect frame = self.titleView.frame;
    frame.origin.x = self.buttonCancel.frame.origin.x + self.buttonCancel.frame.size.width;
    frame.size.width = self.navBar.frame.size.width - frame.origin.x;
    self.titleView.frame = frame;
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    [super setContentBackgroundColor:color];
    self.tableView.backgroundColor = color;
    _contentColor = color;
}

- (void) rebuildRows
{
    [self buildMenu:[NSMutableArray array]];
}

- (void)processNearestWiki:(OAPOI *)poi
{
    int radius = kNearbyPoiMinRadius;
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.location.latitude, self.location.longitude));
    NSMutableArray<OAPOI *> *osmwiki = [NSMutableArray new];
    OAWikipediaPlugin *wikiPlugin = (OAWikipediaPlugin *) [OAPluginsHelper getEnabledPlugin:OAWikipediaPlugin.class];
    NSMutableArray<NSString *> *languagesToShow = [[wikiPlugin getLanguagesToShow] mutableCopy];
    if ([languagesToShow containsObject:@"en"])
    {
        NSInteger index = [languagesToShow indexOfObject:@"en"];
        [languagesToShow replaceObjectAtIndex:index withObject:@""];
    }

    while (osmwiki.count < kNearbyPoiMaxCount && radius <= kNearbyPoiMaxRadius)
    {
        osmwiki = [[OAAmenitySearcher findPOIsByTagName:nil name:nil location:locI categoryName:OSM_WIKI_CATEGORY poiTypeName:nil radius:radius] mutableCopy];
        [osmwiki removeObject:poi];

        if (![wikiPlugin isShowAllLanguages] && [wikiPlugin hasLanguagesFilter])
        {
            NSMutableArray<OAPOI *> *itemsToRemove = [NSMutableArray new];
            for (OAPOI *w in osmwiki)
            {
                if (![w.localizedContent.allKeys firstObjectCommonWithArray:languagesToShow])
                    [itemsToRemove addObject:w];
            }
            [osmwiki removeObjectsInArray:itemsToRemove];
        }

        radius *= kNearbyPoiSearchFactory;
    }
    osmwiki = [[OAMapUtils sortPOI:osmwiki lat:self.location.latitude lon:self.location.longitude] mutableCopy];

    _hasOsmWiki = osmwiki.count > 0 && [osmwiki firstObjectCommonWithArray:osmwiki];
    _nearestWiki = [NSArray arrayWithArray:[osmwiki subarrayWithRange:NSMakeRange(0, MIN(kNearbyPoiMaxCount, osmwiki.count))]];
}

- (void)processNearestPoi:(OAPOI *)poi filter:(OAPOIUIFilter *)filter
{
    NSMutableArray<OAPOI *> *amenities = [NSMutableArray new];
    if (!poi.type.category.isWiki)
    {
        int radius = kNearbyPoiMinRadius;
        while (amenities.count < kNearbyPoiMaxCount && radius <= kNearbyPoiMaxRadius)
        {
            OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.location.latitude, self.location.longitude));
            const auto rect = OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, pointI);
            const auto top = OsmAnd::Utilities::get31LatitudeY(rect.top());
            const auto left = OsmAnd::Utilities::get31LongitudeX(rect.left());
            const auto bottom = OsmAnd::Utilities::get31LatitudeY(rect.bottom());
            const auto right = OsmAnd::Utilities::get31LongitudeX(rect.right());
            amenities = [[filter searchAmenities:top left:left bottom:bottom right:right zoom:-1 matcher:nil filterUnique:NO] mutableCopy];
            radius *= kNearbyPoiSearchFactory;
        }
    
        NSMutableArray<OAPOI *> *filterdAmenities = [NSMutableArray new];
        NSInteger osmObfId = [ObfConstants getOsmObjectId:poi];
        for (OAPOI *amenity in amenities)
        {
            if ([ObfConstants getOsmObjectId:amenity] != osmObfId)
                [filterdAmenities addObject:amenity];
        }

        amenities = [[OAMapUtils sortPOI:filterdAmenities lat:self.location.latitude lon:self.location.longitude] mutableCopy];
    }
    _nearestPoi = amenities.count > 0 ? [NSArray arrayWithArray:[amenities subarrayWithRange:NSMakeRange(0, MIN(kNearbyPoiMaxCount, amenities.count))]] : [NSArray new];
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (BOOL) showNearestPoi
{
    return YES;
}

- (OAPOIUIFilter *) getPoiFilterForType:(OAPOI *)target isWiki:(BOOL)isWiki
{
    if (target)
    {
        OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
        return isWiki ? [helper getTopWikiPoiFilter] : [helper getFilterById:[NSString stringWithFormat:@"std_%@", target.type.name]];
    }
    return nil;
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    return nearby ? self.nearbyRoutes : self.localRoutes;
}

- (void)sendNearbyOtherImagesRequest:(NSMutableArray <AbstractCard *> *)cards
                    onFailureNoCache:(void (^)(void))onFailureNoCache
{
    if (!_onlinePhotoCardsRowInfo)
        return;

    NSString *openPlaceReviewsTagContent = nil;
    NSString *imageTagContent = nil;
    NSString *mapillaryTagContent = nil;
    if ([self.getTargetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = self.getTargetObj;
        openPlaceReviewsTagContent = @(poi.obfId >> 1).stringValue;
        imageTagContent = poi.values[@"image"];
        mapillaryTagContent = poi.values[@"mapillary"];
    }
    
    _otherCardsReady = NO;
    [self addOtherCards:imageTagContent mapillary:mapillaryTagContent cards:cards rowInfo:_onlinePhotoCardsRowInfo onFailureNoCache:onFailureNoCache];
}

- (void)getCard:(NSDictionary *)feature
     onComplete:(void (^)(AbstractCard *card))onComplete
{
    NSString *type = feature[@"type"];

    BOOL isMaplillaryEnabled = !OAIAPHelper.sharedInstance.mapillary.disabled;

    if ([TYPE_MAPILLARY_PHOTO isEqualToString:type] && isMaplillaryEnabled)
    {
        if ([feature[@"imageUrl"] length] == 0 || [feature[@"imageHiresUrl"] length] == 0) {
            [OAMapillaryOsmTagHelper downloadImageByKey:feature[@"key"]
                                                session:[self onlineAndMapillarySession]
                                       onDataDownloaded:^(NSDictionary *result) {
                if (result && onComplete)
                {
                    onComplete([[MapillaryImageCard alloc] initWithData:result]);
                }
                else
                {
                    if (onComplete)
                        onComplete(nil);
                }
            }];
        }
        else
        {
            if (onComplete)
                onComplete([[MapillaryImageCard alloc] initWithData:feature]);
        }
    }
    else if ([TYPE_MAPILLARY_CONTRIBUTE isEqualToString:type] && isMaplillaryEnabled)
    {
        if (onComplete)
            onComplete([[MapillaryContributeCard alloc] init]);
    }
    else if ([TYPE_URL_PHOTO isEqualToString:type])
    {
        if (onComplete)
            onComplete([[UrlImageCard alloc] initWithData:feature]);
    }
    else
    {
        if (onComplete)
            onComplete(nil);
    }
}

- (void)addOtherCards:(NSString *)imageTagContent
            mapillary:(NSString *)mapillaryTagContent
                cards:(NSMutableArray<AbstractCard *> *)cards
              rowInfo:(OAAmenityInfoRow *)nearbyImagesRowInfo
     onFailureNoCache:(void (^)(void))onFailureNoCache
{
    CLLocation *myLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    NSString *preferredLang = [[OAAppSettings sharedManager].settingPrefMapLanguage get] ?: [OAUtilities currentLang];

    NSString *urlString = [NSString stringWithFormat:@"https://osmand.net/api/cm_place?lat=%f&lon=%f&app=%@",
                           self.location.latitude,
                           self.location.longitude,
                           [OAIAPHelper isPaidVersion] ? @"paid" : @"free"];

    if (!NSStringIsEmpty(preferredLang))
        urlString = [urlString stringByAppendingFormat:@"&lang=%@", preferredLang];
    if (myLocation)
        urlString = [urlString stringByAppendingFormat:@"&mloc=%f,%f", myLocation.coordinate.latitude, myLocation.coordinate.longitude];

    if (imageTagContent)
        urlString = [urlString stringByAppendingFormat:@"&osm_image=%@", imageTagContent];
    if (mapillaryTagContent)
        urlString = [urlString stringByAppendingFormat:@"&mapillary=%@", mapillaryTagContent];

    urlString = [[[urlString stringByReplacingOccurrencesOfString:@" " withString:@"_"]
                  stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] copy];

    NSURL *urlObj = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlObj
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:30];

    NSMutableArray<AbstractCard *> *newCards = [NSMutableArray arrayWithArray:cards];
    NSInteger existingCount = cards.count;
    
    __weak __typeof(self) weakSelf = self;
    [[[self onlineAndMapillarySession] dataTaskWithRequest:request
                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;
        if (error && error.code == NSURLErrorCancelled)
            return;
        
        NSData *effectiveData = data;
        NSURLResponse *effectiveResponse = response;

        NSURLRequest *cacheRequest;
        NSString *key = [URLSessionConfigProvider onlineAndMapillaryPhotosAPIKey];
        if ((!data || !response) && [ErrorHelper isInternetConnectionError:error])
        {
            cacheRequest = [strongSelf filteredCacheRequestFromRequest:request];
            NSCachedURLResponse *cached = [URLSessionManager cachedResponseFor:cacheRequest sessionKey:key];
            if (cached)
            {
                effectiveData = cached.data;
                effectiveResponse = cached.response;
            }
            else
            {
                if (onFailureNoCache)
                {
                    dispatch_async(dispatch_get_main_queue(), onFailureNoCache);
                }
                return;
            }
        }
        else
        {
            if ([response isKindOfClass:[NSHTTPURLResponse class]] &&
                ((NSHTTPURLResponse *)response).statusCode == 200 && data)
            {
                cacheRequest = [strongSelf filteredCacheRequestFromRequest:request];
                [URLSessionManager storeResponse:response data:data for:cacheRequest sessionKey:key];
            }
        }
        
        if (!effectiveData)
        {
            NSLog(@"[ERROR] addOtherCards effectiveData is nil, cannot parse JSON.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
            });
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:effectiveData
                                                                 options:NSJSONReadingAllowFragments
                                                                   error:&jsonError];
        if (!jsonDict || ![jsonDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"JSON parse error: %@", jsonError ?: @"Unknown error");
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
            });
            return;
        }

        NSArray<NSDictionary *> *images = jsonDict[@"features"];
        if (images.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
            });
        }
        else
        {
            __block NSInteger count = images.count;
            for (NSDictionary *dict in images)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf getCard:dict onComplete:^(AbstractCard *card) {
                        if (card)
                            [newCards addObject:card];
                        else
                            count--;

                        if (newCards.count == count + existingCount)
                        {
                            [strongSelf onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
                        }
                    }];
                });
            }
        }
    }] resume];
}

- (void)onOtherCardsReady:(NSMutableArray<AbstractCard *> *)cards
                rowInfo:(OAAmenityInfoRow *)nearbyImagesRowInfo
{
    _otherCardsReady = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDisplayingCards:cards];
    });
}

- (NSURLRequest *)filteredCacheRequestFromRequest:(NSURLRequest *)request
{
    NSArray<NSString *> *blockedParams = @[@"mloc", @"app", @"lang"];
    NSString *urlString = request.URL.absoluteString;
    
    BOOL hasBlockedParam = NO;
    for (NSString *param in blockedParams)
    {
        NSString *searchString = [param stringByAppendingString:@"="];
        if ([urlString containsString:searchString])
        {
            hasBlockedParam = YES;
            break;
        }
    }
    
    if (!hasBlockedParam)
        return request;
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    components.queryItems = [components.queryItems filteredArrayUsingPredicate:
                             [NSPredicate predicateWithBlock:^BOOL(NSURLQueryItem *item, NSDictionary *bindings) {
        return ![blockedParams containsObject:item.name];
    }]];
    
    return [NSURLRequest requestWithURL:components.URL];
}

- (void)updateDisplayingCards:(NSMutableArray<AbstractCard *> *)cards
{
    if (_otherCardsReady && _wikiCardsReady)
    {
        if (cards.count > 1)
            [self reorderCards:cards];
        
        // After forming the list of cards, fill the collection
        if (_onlinePhotoCardsRowInfo)
        {
            CollapsableCardsView *collapsableView = (CollapsableCardsView *)_onlinePhotoCardsRowInfo.collapsableView;
            collapsableView.isLoading = NO;
            collapsableView.placeholderImage = [self targetImage];
            [collapsableView setCards:cards];
        }
        if (_mapillaryCardsRowInfo)
        {
            CollapsableCardsView *collapsableView = (CollapsableCardsView *)_mapillaryCardsRowInfo.collapsableView;
            collapsableView.isLoading = NO;
            collapsableView.placeholderImage = [self targetImage];
            [collapsableView setCards:cards];
        }
    }
}

- (void)reorderCards:(NSMutableArray<AbstractCard *> *)cards {
    NSMutableArray *openPlaceCards = [NSMutableArray new];
    NSMutableArray *wikimediaCards = [NSMutableArray new];
    NSMutableArray *mapilaryCards = [NSMutableArray new];
    MapillaryContributeCard *mapilaryContributeCard = nil;

    for (AbstractCard *card in cards) {
        if ([card isKindOfClass:WikiImageCard.class])
            [wikimediaCards addObject:card];
        else if ([card isKindOfClass:MapillaryImageCard.class])
            [mapilaryCards addObject:card];
        else if ([card isKindOfClass:MapillaryContributeCard.class])
            mapilaryContributeCard = (MapillaryContributeCard *)card;
        else if ([card isKindOfClass:UrlImageCard.class])
            [openPlaceCards addObject:card];
    }

    NSMutableArray *orderedCards = [NSMutableArray array];
    [orderedCards addObjectsFromArray:wikimediaCards];
    [orderedCards addObjectsFromArray:mapilaryCards];
    [orderedCards addObjectsFromArray:openPlaceCards];
    
    if (mapilaryContributeCard)
        [orderedCards addObject:mapilaryContributeCard];

    NSOrderedSet *uniqueOrderedSet = [NSOrderedSet orderedSetWithArray:orderedCards];
    [cards setArray:uniqueOrderedSet.array];
}

- (void)buildPhotosRow
{
    BOOL hasPhoto = YES; //TODO: implement later. Move emmty row to bottom of context menu
    NSInteger order = hasPhoto ? kOrderPhotoRow : kOrderPhotoEmptyRow;
    
    OAAmenityInfoRow *nearbyImagesRowInfo = [[OAAmenityInfoRow alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_custom_photo"] textPrefix:nil text:OALocalizedString(@"online_photos") textColor:nil isText:NO needLinks:NO order:order typeName:@"" isPhoneNumber:NO isUrl:NO];
    
    CollapsableCardsView *cardView = [CollapsableCardsView new];
    cardView.contentType = CollapsableCardsTypeOnlinePhoto;
    cardView.delegate = self;
    __weak __typeof(self) weakSelf = self;
    nearbyImagesRowInfo.collapsedChangedCallback = ^(BOOL collapsed) {
        if (!collapsed)
            [weakSelf startLoadingImages];
    };
    nearbyImagesRowInfo.collapsed = [OAAppSettings sharedManager].onlinePhotosRowCollapsed.get;
    nearbyImagesRowInfo.collapsableView = cardView;
    nearbyImagesRowInfo.collapsableView.frame = CGRectMake([OAUtilities getLeftMargin], 0, self.view.frame.size.width, 170);
    [_rows addObject:nearbyImagesRowInfo];

    [self clearContentForRowInfo:_onlinePhotoCardsRowInfo];
    _onlinePhotoCardsRowInfo = nearbyImagesRowInfo;
    
    [self startLoadingImages];
}

- (void)addMapillaryCardsRowInfoIfNeeded
{
    OAMapillaryPlugin *plugin = (OAMapillaryPlugin *) [OAPluginsHelper getPlugin:OAMapillaryPlugin.class];
    if ([plugin isEnabled])
    {
        BOOL hasPhoto = YES; //TODO: implement later. Move emmty row to bottom of context menu
        NSInteger order = hasPhoto ? kOrderMapillaryRow : kOrderMapillaryEmptyRow;
        
        OAAmenityInfoRow *mapillaryCardsRowInfo = [[OAAmenityInfoRow alloc] initWithKey:nil
                                                                     icon:[UIImage imageNamed:@"ic_custom_photo_street"]
                                                               textPrefix:nil
                                                                     text:OALocalizedString(@"street_level_imagery")
                                                                textColor:nil
                                                                   isText:NO
                                                                needLinks:NO
                                                                    order:order
                                                                 typeName:@""
                                                            isPhoneNumber:NO isUrl:NO];

        CollapsableCardsView *cardView = [CollapsableCardsView new];
        cardView.contentType = CollapsableCardsTypeMapillary;
        cardView.delegate = self;
        __weak __typeof(self) weakSelf = self;
        mapillaryCardsRowInfo.collapsedChangedCallback = ^(BOOL collapsed) {
            if (!collapsed)
                [weakSelf startLoadingImages];
        };
        mapillaryCardsRowInfo.collapsed = [OAAppSettings sharedManager].mapillaryPhotosRowCollapsed.get;
        mapillaryCardsRowInfo.collapsableView = cardView;
        mapillaryCardsRowInfo.collapsableView.frame = CGRectMake([OAUtilities getLeftMargin], 0, self.view.frame.size.width, 170);
        [_rows addObject:mapillaryCardsRowInfo];

        [self clearContentForRowInfo:_mapillaryCardsRowInfo];
        _mapillaryCardsRowInfo = mapillaryCardsRowInfo;
    }
}

- (void) addOsmRowInfoIfNeeded
{
    if ([OAPluginsHelper isEnabled:OAOsmEditingPlugin.class])
    {
        NSString *osmUrl = [ObfConstants getOsmUrlForId:self.getTargetObj];
        if (!NSStringIsEmpty(osmUrl))
        {
            [_rows addObject:[[OAAmenityInfoRow alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_custom_osm_edits"] textPrefix:nil text:osmUrl textColor:[UIColor colorNamed:ACColorNameTextColorActive] isText:YES needLinks:YES order:kOrderOsmRow typeName:nil isPhoneNumber:NO isUrl:YES]];
        }
    }
}

- (void)clearContentForRowInfo:(OAAmenityInfoRow *)rowInfo
{
    CollapsableCardsView *cardsView = (CollapsableCardsView *)[rowInfo collapsableView];
    if (cardsView)
    {
        [cardsView clearContent];
        [cardsView removeFromSuperview];
    }
}

- (void)showPOITagsDetails:(OAAmenityInfoRow *)info
{
    POITagsDetailsViewController *tagsDetailsController = [[POITagsDetailsViewController alloc] initWithTags:info.detailsArray];
    tagsDetailsController.tagTitle = info.textPrefix;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tagsDetailsController];
    [self.navController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OAAmenityInfoRow *info = _rows[indexPath.row];
    
    if ([info.typeName isEqualToString:kCollapseDetailsRowType])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
            cell.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:13 weight:UIFontWeightSemibold];
            [cell textIndentsStyle:EOATableViewCellTextIncreasedTopCenterIndentStyle];
            [cell anchorContent:EOATableViewCellContentTopStyle];
        }
        if (self.delegate.isInFullMode)
            cell.titleLabel.text = OALocalizedString(@"shared_string_collapse").upperCase;
        else
            cell.titleLabel.text = OALocalizedString(@"shared_string_details").upperCase;
        return cell;
    }
    else if ([info.typeName isEqualToString:kDescriptionRowType])
    {
        OATextMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
        }
        NSString *label = info.text;
        if (label.length == 0)
        {
            cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCallout];
            cell.textView.text = info.textPrefix;
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        else
        {
            cell.textView.font = [UIFont scaledSystemFontOfSize:14.0];
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.textView.text = label;
            
            CGSize s = [OAUtilities calculateTextBounds:info.text width:self.tableView.bounds.size.width - 38.0 font:[UIFont scaledSystemFontOfSize:14.0]];
            CGFloat h = MIN(188.0, s.height + 10.0);
            h = MAX(48.0, h);
            info.height = h;
        }
        return cell;
    }
    else if ([info.typeName isEqualToString:kShortDescriptionRowType] || [info.typeName isEqualToString:kShortDescriptionWikiRowType] || [info.typeName isEqualToString:kShortDescriptionTravelRowType])
    {
        OATextMultilineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
            
            NSString *label = info.text;
            
            label = [NSString stringWithFormat:@"%@\n\n%@", label, info.textPrefix];
            
            cell.textView.font = [UIFont scaledSystemFontOfSize:14.0];
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.textView.text = label;
            
            CGSize s = [OAUtilities calculateTextBounds:info.text width:self.tableView.bounds.size.width - 38.0 font:[UIFont scaledSystemFontOfSize:14.0]];
            
            //TODO: implement
            
            CGFloat h = s.height + 10.0;
            
//            CGFloat h = MIN(188.0, s.height + 10.0);
//            h = MAX(48.0, h);
            
            info.height = h;
        }
        return cell;
    }
    
    if (!info.isHtml)
    {
        if ([info.collapsableView isKindOfClass:OACollapsableCoordinatesView.class])
        {
            OATargetInfoCollapsableCoordinatesViewCell *cell;
            cell = (OATargetInfoCollapsableCoordinatesViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier]];
            
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoCollapsableCoordinatesViewCell *)[nib objectAtIndex:0];
            }
            
            OACollapsableCoordinatesView *coordinateView = (OACollapsableCoordinatesView *) info.collapsableView;
            [cell setupCellWithLat:coordinateView.lat lon:coordinateView.lon];
            
            cell.collapsableView = coordinateView;
            [cell setCollapsed:info.collapsed rawHeight:[info getRawHeight]];

            return cell;
        }
        if ([info.collapsableView isKindOfClass:OACollapsableWaypointsView.class])
        {
            OATargetInfoCollapsableViewCell* cell;
            cell = (OATargetInfoCollapsableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoCollapsableViewCell *)[nib objectAtIndex:0];
            }
            cell.textView.text = info.text;
            cell.descrLabel.hidden = NO;
            cell.descrLabel.text = info.textPrefix;
            [cell setDescription:info.textPrefix];

            cell.iconView.contentMode = UIViewContentModeCenter;
            [cell setImage:info.icon];
            cell.iconView.tintColor = info.textColor;
            
            OACollapsableWaypointsView *groupView = (OACollapsableWaypointsView *) info.collapsableView;
            cell.collapsableView = groupView;
            [cell setCollapsed:info.collapsed rawHeight:64.];
            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            
            return cell;
        }
        else if (info.collapsable)
        {
            OATargetInfoCollapsableViewCell* cell;
            cell = (OATargetInfoCollapsableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoCollapsableViewCell *)[nib objectAtIndex:0];
            }
            if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
                cell.iconView.contentMode = UIViewContentModeCenter;
            else
                cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.backgroundColor = _contentColor;
            [cell setImage:info.icon];
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            cell.textView.textColor = info.textColor;
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;
            [cell setDescription:nil];
            
            [cell.textView sizeToFit];
            info.height = cell.textView.frame.size.height + 33.0;
            
            cell.collapsableView = info.collapsableView;
            [cell setCollapsed:info.collapsed rawHeight:[info getRawHeight]];

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];

            return cell;
        }
        else
        {
            OATargetInfoViewCell* cell;
            cell = (OATargetInfoViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoViewCell *)[nib objectAtIndex:0];
            }
            if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
                cell.iconView.contentMode = UIViewContentModeCenter;
            else
                cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.backgroundColor = _contentColor;
            cell.iconView.image = info.icon;
            
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            
            if (info.isPhoneNumber || info.isUrl)
                cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            else
                cell.textView.textColor = info.textColor;
            
            cell.textView.font = [info getFont];
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;
            cell.accessoryType = info.detailsArray.count > 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

            return cell;
        }
    }
    else
    {
        OAWebViewCell* cell;
        cell = (OAWebViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAWebViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAWebViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAWebViewCell *)[nib objectAtIndex:0];
        }
        if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
        {
            cell.iconView.contentMode = UIViewContentModeCenter;
        }
        else
        {
            cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
        }
        cell.backgroundColor = _contentColor;
        cell.webView.backgroundColor = _contentColor;
        cell.iconView.image = info.icon;
        [cell.webView loadHTMLString:[kViewPortHtml stringByAppendingString:info.text ?: @""]  baseURL:nil];
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAAmenityInfoRow *info = _rows[indexPath.row];
    [info.collapsableView adjustHeightForWidth:tableView.frame.size.width];
    if ([info.typeName isEqualToString:kGroupRowType])
        return info.height + 16;
    if ([info.typeName isEqualToString:kDescriptionRowType])
        return info.height;
    else if ([info.typeName isEqualToString:kCollapseDetailsRowType] && !self.delegate.isInFullMode && !OAUtilities.isLandscape)
        return info.height + OAUtilities.getBottomMargin;
    else
        return info.height;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAAmenityInfoRow *info = _rows[indexPath.row];
    if (info.collapsable)
        [info.collapsableView adjustHeightForWidth:tableView.frame.size.width];
    return info.height;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OAAmenityInfoRow *info = _rows[indexPath.row];
    if (info.delegate)
    {
        [info.delegate onRowClick:self rowInfo:info];
    }
    else if (info.collapsable)
    {
        info.collapsed = !info.collapsed;
        [UIView transitionWithView:tableView
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
            [tableView reloadData];
        } completion:nil];
        [self calculateContentHeight];
        if (self.delegate)
            [self.delegate contentHeightChanged:0];
    }
    else if (info.isPhoneNumber)
    {
        if ([info.key isEqual:@"phone"] || [info.key isEqual:@"mobile"])
            [OAUtilities callPhone:info.text];
        else
        {
            NSString *url;
            if ([info.key isEqual:@"whatsapp"])
            {
                NSString *phoneNumber = [[info.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                url = [NSString stringWithFormat:kWhatsAppLink, phoneNumber];
            }
            else if ([info.key isEqual:@"viber"])
            {
                url = [NSString stringWithFormat:kViberLink, info.text];
            }
            [OAUtilities callUrl:url];
        }
    }
    else if (info.isUrl)
    {
        if ([info.text containsString:kWikiLink])
        {
            OAIAPHelper *helper = [OAIAPHelper sharedInstance];
            if ([helper.wiki isPurchased])
            {
                [OAWikiArticleHelper showWikiArticle:[[CLLocation alloc] initWithLatitude:self.location.latitude
                                                                                longitude:self.location.longitude]
                                                 url:info.text
                                          sourceView:[tableView cellForRowAtIndexPath:indexPath]];
            }
            else
            {
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
            }
        }
        else if ([info.key isEqual:@"skype"])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kSkypeLink, info.text]];
        }
        else if ([info.text isValidEmail])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kMailLink, info.text]];
        }
        else if ([info.key isEqual:@"facebook"] && ![info.text hasPrefix:@"http"])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kFacebookLink, info.text]];
        }
        else if ([info.key isEqual:@"instagram"] && ![info.text hasPrefix:@"http"])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kInstagramLink, info.text]];
        }
        else
        {
            [OAUtilities callUrl:NSStringIsEmpty(info.hiddenUrl) ? info.text : info.hiddenUrl];
        }
    }
    else if (info.isText && info.moreText)
    {
        if (info.detailsArray.count > 0)
        {
            [self showPOITagsDetails:info];
        }
        else
        {
            OAEditDescriptionViewController *_editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:info.text isNew:NO isEditing:NO readOnly:YES];
            [self.navController pushViewController:_editDescController animated:YES];
        }
    }
    else if ([info.typeName isEqualToString:kCollapseDetailsRowType])
    {
        if (self.delegate.isInFullMode)
            [self.delegate requestHeaderOnlyMode];
        else
            [self.delegate requestFullMode];
        NSIndexPath *collapseDetailsCellIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[collapseDetailsCellIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if ([info.typeName isEqualToString:kDescriptionRowType] || [info.typeName isEqualToString:kCommentRowType])
    {
        OAEditDescriptionViewController *editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:info.text isNew:NO isEditing:NO isComment:[info.typeName isEqualToString:kCommentRowType] readOnly:YES];
        editDescController.delegate = self;
        [self.navController pushViewController:editDescController animated:YES];
    }
    else if ([info.typeName isEqualToString:kShortDescriptionWikiRowType])
    {
        NSString *url = info.hiddenUrl;
        if (NSStringIsEmpty(url))
        {
            if ([self isKindOfClass:OAPOIViewController.class])
            {
                if ([[self getTargetObj] isKindOfClass:OAPOI.class])
                {
                    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
                    if ([helper.wiki isPurchased])
                    {
                        OAWikiWebViewController *wikiController = [[OAWikiWebViewController alloc] initWithPoi:[self getTargetObj]];
                        [OARootViewController.instance.mapPanel.navigationController pushViewController:wikiController animated:YES];
                    }
                    else
                    {
                        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
                    }
                }
            }
        }
        else
        {
            [OAUtilities callUrl:url];
        }
    }
    else if ([info.typeName isEqualToString:kShortDescriptionTravelRowType])
    {
        NSString *routeId = info.hiddenUrl;
        if (!NSStringIsEmpty(routeId) && [[self getTargetObj] isKindOfClass:OAPOI.class])
        {
            OAPOI *poi = [self getTargetObj];
            NSDictionary<NSString *, CLLocation *> *routeIdMap = @{routeId : [poi getLocation]};
            
            SearchTravelArticlesTask *task = [[SearchTravelArticlesTask alloc] initWithRouteIds:routeIdMap callback:^(NSDictionary<NSString *,NSDictionary<NSString *,OATravelArticle *> *> * _Nonnull result) {
                
                //TODO: add fetching correct article if it needed
                if (result.allValues.count > 0 && result.allValues[0].allValues.count >0)
                {
                    NSDictionary<NSString *,OATravelArticle *> *map = result.allValues[0];
                    OATravelArticle *article = map.allValues[0];
                    
                    OATravelArticleDialogViewController *vc = [[OATravelArticleDialogViewController alloc] initWithArticleId:article.generateIdentifier lang:article.lang];
                    [OARootViewController.instance.navigationController pushViewController:vc animated:YES];
                }
            }];
            [task execute];
        }
    }
    else if (info.detailsArray.count > 0)
    {
        [self showPOITagsDetails:info];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:))
    {
        OAAmenityInfoRow *info = _rows[indexPath.row];
        NSString *textToCopy;
        if ([info.collapsableView isKindOfClass:OACollapsableCoordinatesView.class])
            textToCopy = [OAPointDescription getLocationName:self.location.latitude lon:self.location.longitude sh:YES];
        else
            textToCopy = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];

        [[UIPasteboard generalPasteboard] setString:textToCopy];
    }
}

#pragma mark - OACollapsableCardViewDelegate

- (void)onRecalculateHeight {
    [self.tableView reloadData];
    [self calculateContentHeight];
    if (self.delegate)
        [self.delegate contentHeightChanged:0];
}

- (void)startLoadingImages
{
    if (_wikiCardsReady || _otherCardsReady) {
        return;
    }
 
    _wikiCardsReady = NO;
    CollapsableCardsView *onlinePhotoCardsView = (CollapsableCardsView *)_onlinePhotoCardsRowInfo.collapsableView;
    CollapsableCardsView *mapillaryCardsView;
    if (_mapillaryCardsRowInfo)
    {
        mapillaryCardsView = (CollapsableCardsView *)_mapillaryCardsRowInfo.collapsableView;
    }
    
    onlinePhotoCardsView.isLoading = YES;
    if ([self.getTargetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = self.getTargetObj;
        onlinePhotoCardsView.title = poi.nameLocalized ?: poi.name;
    }
    
    __weak __typeof(self) weakSelf = self;
    void (^onFailureNoCache)(void) = ^{
        onlinePhotoCardsView.isLoading = NO;
        NoInternetCard *noInternetCard = [NoInternetCard new];
        noInternetCard.onTryAgainAction = ^{
            if (AFNetworkReachabilityManager.sharedManager.isReachable)
            {
                [weakSelf startLoadingImages];
            }
        };
        [onlinePhotoCardsView setCards:@[noInternetCard]];
        if (mapillaryCardsView)
        {
            [mapillaryCardsView setCards:@[noInternetCard]];
        }
    };
    
    mapillaryCardsView.isLoading = YES;
    [[OAWikiImageHelper sharedInstance] sendNearbyWikiImagesRequest:_onlinePhotoCardsRowInfo targetObj:self.getTargetObj session:[self onlineAndMapillarySession] addOtherImagesOnComplete:^(NSMutableArray <AbstractCard *> *cards) {
        weakSelf.wikiCardsReady = YES;
        [weakSelf sendNearbyOtherImagesRequest:cards onFailureNoCache:onFailureNoCache];
    } onFailureNoCache:onFailureNoCache];
}

- (NSURLSession *)onlineAndMapillarySession
{
    @synchronized (self)
    {
        if (!_onlineAndMapillarySession)
        {
            _onlineAndMapillarySession = [URLSessionManager sessionFor:[URLSessionConfigProvider onlineAndMapillaryPhotosAPIKey]];
        }
    }
    return _onlineAndMapillarySession;
}

#pragma mark - OAEditDescriptionViewControllerDelegate

- (void) descriptionChanged:(NSString *)descr
{
    [self.tableView reloadData];
}

@end
