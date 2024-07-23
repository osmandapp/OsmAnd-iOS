//
//  OATargetInfoViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

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
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OALocationServices.h"
#import "OAPOICategory.h"
#import "OATransportStop.h"
#import "OACollapsableNearestPoiWikiView.h"
#import "OATransportStopRoute.h"
#import "OACollapsableTransportStopRoutesView.h"
#import "OACollapsableCardsView.h"
#import "OANoImagesCard.h"
#import "OAMapillaryImageCard.h"
#import "OAMapillaryContributeCard.h"
#import "OAUrlImageCard.h"
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
#import "OAWikiImageCard.h"
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

#include <OsmAndCore/Utilities.h>

// Links
static NSString *kWikiLink = @".wikipedia.org/w";
static NSString *kWhatsAppLink = @"https://wa.me/%@";
static NSString *kViberLink = @"viber://contact?number=%@";
static NSString *kSkypeLink = @"skype:%@";
static NSString *kMailLink = @"mailto:%@";
static NSString *kInstagramLink = @"https://www.instagram.com/%@";
static NSString *kFacebookLink = @"https://www.facebook.com/%@";

// HTML for ViewPort
static NSString *const kViewPortHtml = @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>";

// Constants for Nearby POI
static const NSInteger kNearbyPoiMaxCount = 10;
static const NSInteger kNearbyPoiMinRadius = 250;
static const NSInteger kNearbyPoiMaxRadius = 1000;
static const NSInteger kNearbyPoiSearchFactory = 2;

@interface OATargetInfoViewController() <OACollapsableCardViewDelegate, OAEditDescriptionViewControllerDelegate>

@property (nonatomic) BOOL wikiCardsReady;

@end

@implementation OATargetInfoViewController
{
    NSMutableArray<OARowInfo *> *_rows;
    CGFloat _contentHeight;
    UIColor *_contentColor;
    NSArray<OAPOI *> *_nearestWiki;
    NSArray<OAPOI *> *_nearestPoi;
    BOOL _hasOsmWiki;
    CGFloat _calculatedWidth;
    
    OARowInfo *_nearbyImagesRowInfo;
    BOOL _otherCardsReady;
}

- (void) setRows:(NSMutableArray<OARowInfo *> *)rows
{
    _rows = rows;
}

- (BOOL) needCoords
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

- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows
{
    [self buildDescription:rows];
    NSArray<OATransportStopRoute *> *localTransportRoutes = [self getLocalTransportStopRoutes];
    NSArray<OATransportStopRoute *> *nearbyTransportRoutes = [self getNearbyTransportStopRoutes];
    if (localTransportRoutes.count > 0)
    {
        OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:OALocalizedString(@"transport_Routes") textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
        rowInfo.collapsable = YES;
        rowInfo.collapsed = NO;
        rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
        ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = localTransportRoutes;
        [_rows addObject:rowInfo];
    }
    if (nearbyTransportRoutes.count > 0)
    {
        NSString *routesWithingDistance = [NSString stringWithFormat:@"%@ %@",  OALocalizedString(@"transport_nearby_routes_within"), [OAOsmAndFormatter getFormattedDistance:kShowStopsRadiusMeters]];
        OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:routesWithingDistance textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
        rowInfo.collapsable = YES;
        rowInfo.collapsed = NO;
        rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
        ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = nearbyTransportRoutes;
        [_rows addObject:rowInfo];
    }
}

- (void) buildDescription:(NSMutableArray<OARowInfo *> *)rows
{
    // implement in subclasses
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    // implement in subclasses
}

- (void) appdendDetailsButtonRow:(NSMutableArray<OARowInfo *> *)rows
{
    if ([self showDetailsButton])
    {
        OARowInfo *collapseDetailsRowCell = [[OARowInfo alloc] initWithKey:nil icon:[OATargetInfoViewController getIcon:nil] textPrefix:nil text:@"" textColor:nil isText:NO needLinks:NO order:0 typeName:kCollapseDetailsRowType isPhoneNumber:NO isUrl:NO];
        [collapseDetailsRowCell setHeight:[self detailsButtonHeight]];
        [rows addObject:collapseDetailsRowCell];
    }
}

- (void) buildRowsInternal:(NSMutableArray<OARowInfo *> *)rows
{
    _rows = rows;

    [self buildTopRows:_rows];
    
    [self appdendDetailsButtonRow:_rows];
    
    [self buildRows:_rows];

    if (self.additionalRows)
    {
        [_rows addObjectsFromArray:self.additionalRows];
    }

    if ([self showNearestWiki] && !OAIAPHelper.sharedInstance.wiki.disabled && [OAPluginsHelper getEnabledPlugin:OAWikipediaPlugin.class])
        [self buildRowsPoi:YES];

    if ([self showNearestPoi])
        [self buildRowsPoi:NO];

    [_rows sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
            return NSOrderedAscending;
        else if (row1.order == row2.order)
            return [row1.typeName localizedCompare:row2.typeName];
        else
            return NSOrderedDescending;
    }];

    [self buildCoordinateRows:rows];
    [self addNearbyImagesIfNeeded];

    _calculatedWidth = 0;
    [self contentHeight:self.tableView.bounds.size.width];
}

- (void)buildRowsPoi:(BOOL)isWiki
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
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:icon textPrefix:nil text:rowText textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsable = YES;
            rowInfo.collapsed = YES;
            rowInfo.collapsableView = [[OACollapsableNearestPoiWikiView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            [((OACollapsableNearestPoiWikiView *) rowInfo.collapsableView) setData:nearest hasItems:(isWiki ? _hasOsmWiki : YES) latitude:self.location.latitude longitude:self.location.longitude filter:filter];
            rowInfo.order = 1000;
            [_rows addObject:rowInfo];
        }
    }
}

- (void) buildDateRow:(NSMutableArray<OARowInfo *> *)rows timestamp:(NSDate *)timestamp
{
    if (timestamp)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        NSString *formattedDate = [dateFormatter stringFromDate:timestamp];
        OARowInfo *dateRowCell = [[OARowInfo alloc] initWithKey:nil icon:[OATargetInfoViewController getIcon:@"ic_custom_date"] textPrefix:nil text:formattedDate textColor:nil isText:NO needLinks:NO order:3 typeName:kTimestampRowType isPhoneNumber:NO isUrl:NO];
        [rows addObject:dateRowCell];
    }
}

- (void) buildCommentRow:(NSMutableArray<OARowInfo *> *)rows comment:(NSString *)comment
{
    if (comment.length > 0)
    {
        OARowInfo *commentRow = [[OARowInfo alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_description"] textPrefix:nil text:comment textColor:nil isText:YES needLinks:NO order:4 typeName:kCommentRowType isPhoneNumber:NO isUrl:NO];
        [rows addObject:commentRow];
    }
}

- (void)buildCoordinateRows:(NSMutableArray<OARowInfo *> *)rows
{
    if ([self needCoords])
    {
        OARowInfo *coordinatesRow = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:@"" textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
        coordinatesRow.collapsed = YES;
        coordinatesRow.collapsable = YES;
        OACollapsableCoordinatesView *collapsableView = [[OACollapsableCoordinatesView alloc] initWithFrame:CGRectMake(0, 0, 320, 100) lat:self.location.latitude lon:self.location.longitude];
        coordinatesRow.collapsableView = collapsableView;
        [rows addObject:coordinatesRow];
    }
}

- (void) calculateRowsHeight:(CGFloat)width
{
    CGFloat regularTextWidth = width - kMarginLeft - kMarginRight;
    CGFloat collapsableTitleWidth = width - kMarginLeft - kCollapsableTitleMarginRight;
    for (OARowInfo *row in _rows)
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
            CGSize bounds = [OAUtilities calculateTextBounds:text width:textWidth height:150.0 font:[row getFont]];
            
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
    for (OARowInfo *row in _rows)
        h += row.height;

    _contentHeight = h;
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
    [self buildRowsInternal:[NSMutableArray array]];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    [super setContentBackgroundColor:color];
    self.tableView.backgroundColor = color;
    _contentColor = color;
}

- (void) rebuildRows
{
    [self buildRowsInternal:[NSMutableArray array]];
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
        osmwiki = [[OAPOIHelper findPOIsByTagName:nil name:nil location:locI categoryName:OSM_WIKI_CATEGORY poiTypeName:nil radius:radius] mutableCopy];
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
            amenities = [[filter searchAmenities:top left:left bottom:bottom right:right zoom:-1 matcher:nil] mutableCopy];
            [amenities removeObject:poi];
            radius *= kNearbyPoiSearchFactory;
        }
        amenities = [[OAMapUtils sortPOI:amenities lat:self.location.latitude lon:self.location.longitude] mutableCopy];
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

- (void)sendNearbyOtherImagesRequest:(NSMutableArray <OAAbstractCard *> *)cards
{
    if (!_nearbyImagesRowInfo)
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
    [self addOtherCards:imageTagContent mapillary:mapillaryTagContent cards:cards rowInfo:_nearbyImagesRowInfo];
}

- (void)getCard:(NSDictionary *)feature
     onComplete:(void (^)(OAAbstractCard *card))onComplete
{
    NSString *type = feature[@"type"];

    BOOL isMaplillaryEnabled = !OAIAPHelper.sharedInstance.mapillary.disabled;

    if ([TYPE_MAPILLARY_PHOTO isEqualToString:type] && isMaplillaryEnabled)
    {
        [OAMapillaryOsmTagHelper downloadImageByKey:feature[@"key"]
                                   onDataDownloaded:^(NSDictionary *result) {
            if (result && onComplete)
                onComplete([[OAMapillaryImageCard alloc] initWithData:result]);
        }];
    }
    else if ([TYPE_MAPILLARY_CONTRIBUTE isEqualToString:type] && isMaplillaryEnabled)
    {
        if (onComplete)
            onComplete([[OAMapillaryContributeCard alloc] init]);
    }
    else if ([TYPE_URL_PHOTO isEqualToString:type])
    {
        if (onComplete)
            onComplete([[OAUrlImageCard alloc] initWithData:feature]);
    }
    else
    {
        if (onComplete)
            onComplete(nil);
    }
}

- (void)addOtherCards:(NSString *)imageTagContent mapillary:(NSString *)mapillaryTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    CLLocation *myLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *preferredLang = [settings.settingPrefMapLanguage get];
    if (!preferredLang)
        preferredLang = [OAUtilities currentLang];

    NSString *urlString = [NSString stringWithFormat:@"https://osmand.net/api/cm_place?lat=%f&lon=%f&app=%@",
                           self.location.latitude,
                           self.location.longitude,
                           [OAIAPHelper isPaidVersion] ? @"paid" : @"free"];

    if (preferredLang && preferredLang.length > 0)
        urlString = [urlString stringByAppendingFormat:@"&lang=%@", preferredLang];
    if (myLocation)
        urlString = [urlString stringByAppendingFormat:@"&mloc=%f,%f", myLocation.coordinate.latitude, myLocation.coordinate.longitude];

    if (imageTagContent)
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&osm_image=%@", imageTagContent]];
    if (mapillaryTagContent)
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&mapillary=%@", mapillaryTagContent]];

    NSInteger cardsCount = cards.count;
    NSURL *urlObj = [[NSURL alloc] initWithString:[[urlString stringByReplacingOccurrencesOfString:@" "  withString:@"_"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSMutableArray<OAAbstractCard *> *newCards = [NSMutableArray arrayWithArray:cards];
    [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data && !error)
            {
                NSString *safeCharsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSData *safeCharsData = [safeCharsString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:safeCharsData options:NSJSONReadingAllowFragments error:&error];
                if (jsonDict)
                {
                    NSArray<NSDictionary *> *images = jsonDict[@"features"];
                    if (images.count == 0)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
                        });
                    }
                    else
                    {
                        NSInteger __block count = images.count;
                        for (NSDictionary *dict in images)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self getCard:dict onComplete:^(OAAbstractCard *card) {
                                    if (card)
                                    {
                                        [newCards addObject:card];
                                        if (newCards.count == count + cardsCount)
                                            [self onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
                                    }
                                    else
                                    {
                                        count--;
                                        if (newCards.count == count + cardsCount)
                                            [self onOtherCardsReady:newCards rowInfo:nearbyImagesRowInfo];
                                    }
                                }];
                            });
                        }
                    }
                }
            }
        }
    }] resume];
}

- (void)onOtherCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _otherCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (void)updateDisplayingCards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    if (_otherCardsReady && _wikiCardsReady)
    {
        if (cards.count == 0)
            [cards addObject:[[OANoImagesCard alloc] init]];
        else if (cards.count > 1)
            [self removeDuplicatesFromCards:cards];

        if (nearbyImagesRowInfo)
            [((OACollapsableCardsView *) nearbyImagesRowInfo.collapsableView) setCards:cards];
        
        _otherCardsReady = _wikiCardsReady = NO;
    }
}

- (void)removeDuplicatesFromCards:(NSMutableArray<OAAbstractCard *> *)cards
{
    NSMutableArray *openPlaceCards = [NSMutableArray new];
    NSMutableArray *wikimediaCards = [NSMutableArray new];
    NSMutableArray *mapilaryCards = [NSMutableArray new];
    OAMapillaryContributeCard *mapilaryContributeCard = nil;
    
    for (OAAbstractCard *card in cards)
    {
        if ([card isKindOfClass:OAWikiImageCard.class])
            [wikimediaCards addObject:card];
        if ([card isKindOfClass:OAMapillaryImageCard.class])
            [mapilaryCards addObject:card];
        else if ([card isKindOfClass:OAMapillaryContributeCard.class])
            mapilaryContributeCard = (OAMapillaryContributeCard *)card;
    }
    if (wikimediaCards.count > 0)
    {
        NSArray *sortedWikimediaCards = [wikimediaCards sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(OAWikiImageCard *)a imageHiresUrl];
            NSString *second = [(OAWikiImageCard *)b imageHiresUrl];
            return [first compare:second];
        }];

        [wikimediaCards removeAllObjects];
        [wikimediaCards addObject:sortedWikimediaCards.firstObject];
        OAWikiImageCard *previousCard = sortedWikimediaCards.firstObject;
        for (int i = 1; i < sortedWikimediaCards.count; i++)
        {
            OAWikiImageCard *card = sortedWikimediaCards[i];
            if (![card.imageHiresUrl isEqualToString:previousCard.imageHiresUrl])
            {
                [wikimediaCards addObject:card];
                previousCard = card;
            }
        }
    }
    [cards removeAllObjects];
    [cards addObjectsFromArray:openPlaceCards];
    [cards addObjectsFromArray:wikimediaCards];
    [cards addObjectsFromArray:mapilaryCards];
    if (mapilaryContributeCard)
        [cards addObject:mapilaryContributeCard];
}

- (void) addNearbyImagesIfNeeded
{
    if (!AFNetworkReachabilityManager.sharedManager.isReachable)
        return;

    OARowInfo *nearbyImagesRowInfo = [[OARowInfo alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_custom_photo"] textPrefix:nil text:OALocalizedString(@"mapil_images_nearby") textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];

    OACollapsableCardsView *cardView = [[OACollapsableCardsView alloc] init];
    cardView.delegate = self;
    nearbyImagesRowInfo.collapsable = YES;
    nearbyImagesRowInfo.collapsed = [OAAppSettings sharedManager].onlinePhotosRowCollapsed.get;
    nearbyImagesRowInfo.collapsableView = cardView;
    nearbyImagesRowInfo.collapsableView.frame = CGRectMake([OAUtilities getLeftMargin], 0, 320, 100);
    [_rows addObject:nearbyImagesRowInfo];
    
    _nearbyImagesRowInfo = nearbyImagesRowInfo;
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OARowInfo *info = _rows[indexPath.row];
    
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
            cell.textView.textColor = info.textColor;
            cell.textView.font = [info getFont];
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;
            cell.accessoryType = [info.key isEqualToString:@"name"] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

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
        [cell.webView loadHTMLString:[kViewPortHtml stringByAppendingString:info.text]  baseURL:nil];
        
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
    OARowInfo *info = _rows[indexPath.row];
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
    OARowInfo *info = _rows[indexPath.row];
    if (info.collapsable)
        [info.collapsableView adjustHeightForWidth:tableView.frame.size.width];
    return info.height;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OARowInfo *info = _rows[indexPath.row];
    if (info.delegate)
    {
        [info.delegate onRowClick:self rowInfo:info];
    }
    else if (info.collapsable)
    {
        info.collapsed = !info.collapsed;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
            [OAUtilities callUrl:info.text];
        }
    }
    else if (info.isText && info.moreText)
    {
        OAEditDescriptionViewController *_editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:info.text isNew:NO isEditing:NO readOnly:YES];
        [self.navController pushViewController:_editDescController animated:YES];
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
    else if ([info.key isEqualToString:@"name"])
    {
        NameTagsDetailsViewController *tagsDetailsController = [[NameTagsDetailsViewController alloc] initWithTags:info.detailsArray];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:tagsDetailsController];
        [self.navController presentViewController:navigationController animated:YES completion:nil];
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
        OARowInfo *info = _rows[indexPath.row];
        NSString *textToCopy;
        if ([info.collapsableView isKindOfClass:OACollapsableCoordinatesView.class])
            textToCopy = [OAPointDescription getLocationName:self.location.latitude lon:self.location.longitude sh:YES];
        else
            textToCopy = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];

        [[UIPasteboard generalPasteboard] setString:textToCopy];
    }
}

#pragma mark - OACollapsableCardViewDelegate

- (void)onViewExpanded
{
    _wikiCardsReady = NO;
    if (_nearbyImagesRowInfo)
    {
        OACollapsableCardsView *cardsView = (OACollapsableCardsView *) _nearbyImagesRowInfo.collapsableView;
        [cardsView setCards:@[[[OAImageCard alloc] initWithData:@{@"key": @"loading"}]]];
    }

    __weak OATargetInfoViewController *selfWeak = self;
    [[OAWikiImageHelper sharedInstance] sendNearbyWikiImagesRequest:_nearbyImagesRowInfo targetObj:self.getTargetObj addOtherImagesOnComplete:^(NSMutableArray <OAAbstractCard *> *cards) {
        selfWeak.wikiCardsReady = YES;
        [selfWeak sendNearbyOtherImagesRequest:cards];
    }];
}

#pragma mark - OAEditDescriptionViewControllerDelegate

- (void) descriptionChanged:(NSString *)descr
{
    [self.tableView reloadData];
}

@end
