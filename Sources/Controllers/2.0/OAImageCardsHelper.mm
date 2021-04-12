//
//  OAImageCardsHelper.m
//  OsmAnd
//
//  Created by nnngrach on 09.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAImageCardsHelper.h"

#import "OAPOI.h"
#import "OAPOIHelper.h"

#import "OANoImagesCard.h"
#import "OAMapillaryImageCard.h"
#import "OAMapillaryContributeCard.h"
#import "OAUrlImageCard.h"
#import "Reachability.h"

#import "OACollapsableWikiView.h"
#import "OACollapsableCardsView.h"


#import "OsmAndApp.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "Localization.h"

#import "CocoaSecurity.h"

#include <OsmAndCore/Utilities.h>

@implementation OARowInfo

- (instancetype) initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl
{
    self = [super init];
    if (self)
    {
        _key = key;
        _icon = icon;
        _icon = [_icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _textPrefix = textPrefix;
        _text = text;
        _textColor = textColor;
        _isText = isText;
        _needLinks = needLinks;
        _order = order;
        _typeName = typeName;
        _isPhoneNumber = isPhoneNumber;
        _isUrl = isUrl;
    }
    return self;
}

- (int) height
{
    if (_collapsable && _collapsableView && !_collapsed)
        return _height + _collapsableView.frame.size.height;
    else
        return _height;
}

- (int) getRawHeight
{
    return _height;
}

- (UIFont *) getFont
{
    return [UIFont systemFontOfSize:17.0 weight:_isUrl ? UIFontWeightMedium : UIFontWeightRegular];
}

@end


@interface OAImageCardsHelper() <OACollapsableCardViewDelegate>

@end

@implementation OAImageCardsHelper 
{
    OARowInfo *_nearbyImagesRowInfo;
    BOOL _wikidataCardsReady;
    BOOL _wikimediaCardsReady;
    BOOL _otherCardsReady;
}

- (id) getTargetObj
{
    return _targetObj;
}

- (void)sendNearbyImagesRequest:(OARowInfo *)nearbyImagesRowInfo
{
    OACollapsableCardsView *cardsView = (OACollapsableCardsView *)nearbyImagesRowInfo.collapsableView;
    if (!nearbyImagesRowInfo || cardsView.cards.count > 0)
        return;
    
    [cardsView setCards:@[[[OAImageCard alloc] initWithData:@{@"key" : @"loading"}]]];
    NSMutableArray <OAAbstractCard *> *cards = [NSMutableArray new];
    NSString *imageTagContent = nil;
    NSString *mapillaryTagContent = nil;
    NSString *wikimediaTagContent = nil;
    NSString *wikidataTagContent = nil;
    if ([self.getTargetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = self.getTargetObj;
        imageTagContent = poi.values[@"image"];
        mapillaryTagContent = poi.values[@"mapillary"];
        wikimediaTagContent = poi.values[@"wikimedia_commons"];
        wikidataTagContent = poi.values[@"wikidata"];
    }
    _wikidataCardsReady = NO;
    _wikimediaCardsReady = NO;
    _otherCardsReady = NO;
    [self addWikimediaCards:wikimediaTagContent cards:cards rowInfo:nearbyImagesRowInfo];
    [self addWikidataCards:wikidataTagContent cards:cards rowInfo:nearbyImagesRowInfo];
    [self addOtherCards:imageTagContent mapillary:mapillaryTagContent cards:cards rowInfo:nearbyImagesRowInfo];
}

- (void) addWikidataCards:(NSString *)wikidataTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    if (wikidataTagContent && [wikidataTagContent hasPrefix:@"Q"])
    {
        NSURL *urlObj = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"https://www.wikidata.org/w/api.php?action=wbgetclaims&property=P18&entity=%@&format=json", wikidataTagContent]];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            OAUrlImageCard *resultCard = nil;
            if (((NSHTTPURLResponse *)response).statusCode == 200)
            {
                if (data && !error)
                {
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    if (jsonDict)
                    {
                        try {
                            NSArray *records = jsonDict[@"claims"][@"P18"];
                            if (records && records.count > 0)
                            {
                                NSString *imageName = records.firstObject[@"mainsnak"][@"datavalue"][@"value"];
                                if (imageName)
                                    resultCard = [self createWikimediaCard:[NSString stringWithFormat:@"File:%@",imageName] isFromWikidata:YES];
                            }
                        }
                        catch(NSException *e)
                        {
                            NSLog(@"Wikidata image json serialising error");
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (resultCard)
                    [cards addObject:resultCard];
                [self onWikidataCardsReady:cards rowInfo:nearbyImagesRowInfo];
            });
        }] resume];
    }
    else
    {
        [self onWikidataCardsReady:cards rowInfo:nearbyImagesRowInfo];
    }
}

- (void) onWikidataCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _wikidataCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (void) addWikimediaCards:(NSString *)wikiMediaTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    NSString *wikimediaFilePrefix = @"File:";
    NSString *wikimediaCategoryPrefix = @"Category:";
    
    if (wikiMediaTagContent && [wikiMediaTagContent hasPrefix:wikimediaFilePrefix])
    {
        OAUrlImageCard *card = [self createWikimediaCard:wikiMediaTagContent isFromWikidata:NO];
        if (card)
        {
            [cards addObject:card];
            [self onWikimediaCardsReady:cards rowInfo:nearbyImagesRowInfo];
        }
    }
    else if (wikiMediaTagContent && [wikiMediaTagContent hasPrefix:wikimediaCategoryPrefix])
    {
        NSString *urlSafeFileName = [[wikiMediaTagContent stringByReplacingOccurrencesOfString:@" "  withString:@"_"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *url = [NSString stringWithFormat:@"https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=%@&cmlimit=500&format=json", urlSafeFileName];
        NSURL *urlObj = [[NSURL alloc] initWithString:url];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSMutableArray<OAAbstractCard *> *resultCards = [NSMutableArray array];
            if (((NSHTTPURLResponse *)response).statusCode == 200)
            {
                if (data)
                {
                    NSError *error;
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    NSDictionary *imagesDict = jsonDict[@"query"][@"categorymembers"];
                    if (!error && imagesDict)
                    {
                        for (NSDictionary *imageDict in imagesDict)
                        {
                            NSString *imageName = imageDict[@"title"];
                            if (imageName)
                            {
                                OAAbstractCard *card = [self createWikimediaCard:imageName isFromWikidata:NO];
                                if (card)
                                    [resultCards addObject:card];
                            }
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [cards addObjectsFromArray:resultCards];
                [self onWikimediaCardsReady:cards rowInfo:nearbyImagesRowInfo];
            });
        }] resume];
    }
    else
    {
        [self onWikimediaCardsReady:cards rowInfo:nearbyImagesRowInfo];
    }
}

- (void) onWikimediaCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _wikimediaCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (OAUrlImageCard *) createWikimediaCard:(NSString *)wikiMediaTagContent isFromWikidata:(BOOL)isFromWikidata
{
    NSString *wikimediaFilePrefix = @"File:";
    NSString *imageFileName = [wikiMediaTagContent substringWithRange:NSMakeRange(wikimediaFilePrefix.length, wikiMediaTagContent.length - wikimediaFilePrefix.length)];
    NSString *preparedFileName = [imageFileName stringByReplacingOccurrencesOfString:@" "  withString:@"_"];
    NSString *urlSafeFileName = [preparedFileName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    
    NSString *hash = [CocoaSecurity md5:preparedFileName].hexLower;
    NSString *hashFirstPart = [hash substringWithRange:NSMakeRange(0, 1)];
    NSString *hashSecondPart = [hash substringWithRange:NSMakeRange(0, 2)];
    
    NSString *thumbSize = @"500";
    NSString *url = [NSString stringWithFormat:@"https://commons.wikimedia.org/wiki/%@", [wikiMediaTagContent stringByReplacingOccurrencesOfString:@" "  withString:@"_"]];
    NSString *imageHiResUrl = [NSString stringWithFormat:@"https://upload.wikimedia.org/wikipedia/commons/%@/%@/%@", hashFirstPart, hashSecondPart, urlSafeFileName];
    NSString *imageStubUrl = [NSString stringWithFormat:@"https://upload.wikimedia.org/wikipedia/commons/thumb/%@/%@/%@/%@px-%@", hashFirstPart, hashSecondPart, urlSafeFileName, thumbSize, urlSafeFileName];
    NSString *type = isFromWikidata ? @"wikidata-photo" : @"wikimedia-photo";
    
    NSDictionary *wikimediaFeature = @{
        @"type": type,
        @"lat": [NSNumber numberWithDouble:self.location.latitude],
        @"lon": [NSNumber numberWithDouble:self.location.longitude],
        @"key": wikiMediaTagContent,
        @"title": imageFileName,
        @"url": url,
        @"imageUrl": imageStubUrl,
        @"imageHiresUrl": imageHiResUrl,
        @"username": @"",
        @"timestamp": @"",
        @"externalLink": @NO,
        @"360": @NO
    };
    
    return (OAUrlImageCard *)[self getCard: wikimediaFeature];
}

- (OAAbstractCard *) getCard:(NSDictionary *) feature
{
    NSString *type = feature[@"type"];
    if ([TYPE_MAPILLARY_PHOTO isEqualToString:type])
        return [[OAMapillaryImageCard alloc] initWithData:feature];
    else if ([TYPE_MAPILLARY_CONTRIBUTE isEqualToString:type])
        return [[OAMapillaryContributeCard alloc] init];
    else if ([TYPE_URL_PHOTO isEqualToString:type])
        return [[OAUrlImageCard alloc] initWithData:feature];
    else if ([TYPE_WIKIMEDIA_PHOTO isEqualToString:type])
        return [[OAUrlImageCard alloc] initWithData:feature];
    else if ([TYPE_WIKIDATA_PHOTO isEqualToString:type])
        return [[OAUrlImageCard alloc] initWithData:feature];
    
    return nil;
}

- (void) addOtherCards:(NSString *)imageTagContent mapillary:(NSString *)mapillaryTagContent  cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    NSString *urlString = [NSString stringWithFormat:@"https://osmand.net/api/cm_place?lat=%f&lon=%f",
    self.location.latitude, self.location.longitude];
    if (imageTagContent)
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&osm_image=%@", imageTagContent]];
    if (mapillaryTagContent)
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&osm_mapillary_key=%@", mapillaryTagContent]];
    
    NSURL *urlObj = [[NSURL alloc] initWithString:[[urlString stringByReplacingOccurrencesOfString:@" "  withString:@"_"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSMutableArray<OAAbstractCard *> *resultCards = [NSMutableArray array];
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data)
            {
                NSError *error;
                NSString *safeCharsString = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                NSData *safeCharsData = [safeCharsString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:safeCharsData options:NSJSONReadingAllowFragments error:&error];
                if (!error)
                {
                    for (NSDictionary *dict in jsonDict[@"features"])
                    {
                        OAAbstractCard *card = [self getCard:dict];
                        if (card)
                            [resultCards addObject:card];
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [cards addObjectsFromArray:resultCards];
            [self onOtherCardsReady:cards rowInfo:nearbyImagesRowInfo];
        });
    }] resume];
}

- (void) onOtherCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _otherCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (void) updateDisplayingCards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    if (_wikidataCardsReady && _wikimediaCardsReady && _otherCardsReady)
    {
        if (cards.count == 0)
            [cards addObject:[[OANoImagesCard alloc] init]];
        else if (cards.count > 1)
            [self removeDublicatesFromCards:cards];
    
        [((OACollapsableCardsView *)nearbyImagesRowInfo.collapsableView) setCards:cards];
    }
}

- (void) removeDublicatesFromCards:(NSMutableArray<OAAbstractCard *> *)cards
{
    NSMutableArray *wikimediaCards = [NSMutableArray new];
    NSMutableArray *mapilaryCards = [NSMutableArray new];
    OAMapillaryContributeCard *mapilaryContributeCard = nil;
    
    for (OAAbstractCard *card in cards)
    {
        if ([card isKindOfClass:OAUrlImageCard.class])
            [wikimediaCards addObject:card];
        else if ([card isKindOfClass:OAMapillaryImageCard.class])
            [mapilaryCards addObject:card];
        else if ([card isKindOfClass:OAMapillaryContributeCard.class])
            mapilaryContributeCard = card;
    }
    if (wikimediaCards.count > 0)
    {
        NSArray *sortedWikimediaCards = [wikimediaCards sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(OAUrlImageCard *)a imageHiresUrl];
            NSString *second = [(OAUrlImageCard *)b imageHiresUrl];
            return [first compare:second];
        }];
        
        [wikimediaCards removeAllObjects];
        [wikimediaCards addObject:sortedWikimediaCards.firstObject];
        OAUrlImageCard *previousCard = sortedWikimediaCards.firstObject;
        for (int i = 1; i < sortedWikimediaCards.count; i++)
        {
            OAUrlImageCard *card = sortedWikimediaCards[i];
            if (![card.imageHiresUrl isEqualToString:previousCard.imageHiresUrl])
            {
                [wikimediaCards addObject:card];
                previousCard = card;
            }
        }
    }
    
    [cards removeAllObjects];
    [cards addObjectsFromArray:wikimediaCards];
    [cards addObjectsFromArray:mapilaryCards];
    if (mapilaryContributeCard)
        [cards addObject:mapilaryContributeCard];
}

- (OARowInfo *) addNearbyImagesIfNeeded
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
        return nil;
    
    OARowInfo *nearbyImagesRowInfo = [[OARowInfo alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_custom_photo"] textPrefix:nil text:OALocalizedString(@"mapil_images_nearby") textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];

    OACollapsableCardsView *cardView = [[OACollapsableCardsView alloc] init];
    cardView.delegate = self;
    nearbyImagesRowInfo.collapsable = YES;
    nearbyImagesRowInfo.collapsed = [OAAppSettings sharedManager].onlinePhotosRowCollapsed;
    nearbyImagesRowInfo.collapsableView = cardView;
    nearbyImagesRowInfo.collapsableView.frame = CGRectMake([OAUtilities getLeftMargin], 0, 320, 100);
    
    _nearbyImagesRowInfo = nearbyImagesRowInfo;
    return _nearbyImagesRowInfo;
}

#pragma mark - OACollapsableCardViewDelegate

- (void) onViewExpanded
{
    [self sendNearbyImagesRequest:_nearbyImagesRowInfo];
}

@end
