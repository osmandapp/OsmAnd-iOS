//
//  OAWikiImageHelper.mm
//  OsmAnd
//
//  Created by Skalii on 05.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <CocoaSecurity.h>
#import "OAWikiImageHelper.h"
#import "OATargetInfoViewController.h"
#import "OAPOI.h"
#import "OsmAnd_Maps-Swift.h"

typedef NS_ENUM(NSInteger, EOAWikiImageType) {
    EOAWikiImageTypeWikimedia = 0,
    EOAWikiImageTypeWikidata
};

static NSArray<NSNumber *> *cardTypes = @[@(EOAWikiImageTypeWikimedia), @(EOAWikiImageTypeWikidata)];

static NSString * const kWikipediaShortLink = @".wikipedia.org/wiki/";

@interface OAWikiImageHelper ()

typedef void(^OAWikiImageHelperOtherImages)(NSMutableArray<AbstractCard *> *cards);
@property OAWikiImageHelperOtherImages addOtherImagesFunction;

@end

@implementation OAWikiImageHelper
{
    NSMutableArray<NSNumber *> *_cardTypesReady;
    NSMutableArray<WikiImage *> *_foundImages;
}

+ (OAWikiImageHelper *)sharedInstance
{
    static OAWikiImageHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWikiImageHelper alloc] init];
    });
    return _sharedInstance;
}

- (void)sendNearbyWikiImagesRequest:(OARowInfo *)nearbyImagesRowInfo
                          targetObj:(id)targetObj
           addOtherImagesOnComplete:(void (^)(NSMutableArray <AbstractCard *> *cards))addOtherImagesOnComplete;
{
    if (!nearbyImagesRowInfo)
        return;

    _addOtherImagesFunction = addOtherImagesOnComplete;
    NSMutableArray <AbstractCard *> *cards = [NSMutableArray new];

    if ([targetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = targetObj;

        NSString *wikiCategory = @"";
        NSString *wikidataId = @"";
        NSString *url = @"";
        NSArray<NSString *> *keys = poi.values.allKeys;
        
        if ([keys containsObject:WIKIMEDIA_COMMONS_TAG])
        {
            NSString *wikimediaCommons = poi.values[WIKIMEDIA_COMMONS_TAG];
            if ([wikimediaCommons hasPrefix:WIKIMEDIA_FILE])
            {
                NSString *imageFileName = [wikimediaCommons stringByReplacingOccurrencesOfString:WIKIMEDIA_FILE withString:@""];
                WikiImage *wikiImage = [self getWikiImage:imageFileName];
                WikiImageCard *card = [[WikiImageCard alloc] initWithWikiImage:wikiImage type:@"wikimedia-photo"];
                if (card)
                    [cards addObject:card];
            }
            else if ([wikimediaCommons hasPrefix:WIKIMEDIA_CATEGORY])
            {
                wikiCategory = [wikimediaCommons stringByReplacingOccurrencesOfString:WIKIMEDIA_CATEGORY withString:@""];
                url = [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"category=", wikiCategory];
            }
        }
        if ([keys containsObject:WIKIDATA_TAG])
        {
            wikidataId = poi.values[WIKIDATA_TAG];
            url = url.length == 0
                ? [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"article=", wikidataId]
                : [url stringByAppendingFormat:@"&%@%@", @"article=", wikidataId];
        }
        if ([keys containsObject:WIKIPEDIA_TAG])
        {
            NSString *wikiTitle = poi.values[WIKIPEDIA_TAG];

            NSInteger urlInd = [wikiTitle indexOf:kWikipediaShortLink];
            if (urlInd > 0)
            {
                NSString *prefix = [wikiTitle substringToIndex:urlInd];
                NSString *lang = [[prefix substringFromIndex:[prefix lastIndexOf:@"/"] + 1] stringByReplacingOccurrencesOfString:@"/" withString:@""];
                NSString *title = [wikiTitle substringFromIndex:urlInd + kWikipediaShortLink.length];
                wikiTitle = [NSString stringWithFormat:@"%@:%@", lang, title];
            }

            url = url.length == 0
                ? [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"wiki=", wikiTitle]
                : [url stringByAppendingFormat:@"&%@%@", @"wiki=", wikiTitle];
            
            url = [url stringByAppendingFormat:@"&addMetaData=true"];
        }

        if (USE_OSMAND_WIKI_API)
        {
            if (url.length > 0)
            {
                url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                [self addOsmandAPIImageList:url cards:cards];
            }
            else
            {
                [self runCallback:cards];
            }
        }
        else
        {
            if (wikidataId.length == 0 && wikiCategory.length == 0)
            {
                [self runCallback:cards];
            }
            else
            {
                _cardTypesReady = [NSMutableArray array];
                _foundImages = [NSMutableArray array];
                
                if (wikidataId.length == 0)
                    [_cardTypesReady addObject:@(EOAWikiImageTypeWikidata)];
                else
                    [self addWikidataImageCards:wikidataId cards:cards];
                
                if (wikiCategory.length == 0)
                    [_cardTypesReady addObject:@(EOAWikiImageTypeWikimedia)];
                else
                    [self addWikimediaCardsFromCategory:wikiCategory cards:cards depth:0 prepared:YES];
            }
        }
    }
    else
    {
        [self runCallback:cards];
    }
}

- (void)addOsmandAPIImageList:(NSString *)url cards:(NSMutableArray<AbstractCard *> *)cards
{
    NSURL *urlObj = [NSURL URLWithString:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data && !error)
            {
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (!error && jsonDict)
                {
                    try {
                        NSArray<NSString *> *images = jsonDict[@"features-v2"];
                        for (NSDictionary<NSString *, NSString *> *dic in images)
                        {
                            if (dic[@"image"])
                            {
                                WikiImage *wikiImage = [self getOsmandApiWikiImage:dic[@"image"]];
                                [wikiImage parseMetaDataWith:dic];
                                if (wikiImage)
                                {
                                    WikiImageCard *card = [[WikiImageCard alloc] initWithWikiImage:wikiImage type:@"wikimedia-photo"];
                                    if (card)
                                        [cards addObject:card];
                                }
                            }
                        }
                    }
                    catch(NSException *e)
                    {
                        NSLog(@"OsmandApi photos json serialising error: %@", e.reason);
                    }
                }
                else
                {
                    NSLog(@"OsmandApi photos error parsing json: %@", error);
                }
            }
            else
            {
                NSLog(@"OsmandApi photos error: %@", error);
            }
        }
        else
        {
            NSLog(@"Error retrieving OsmandApi photos: %@", error);
        }
        [self runCallback:cards];
    }] resume];
}

- (WikiImage *)getOsmandApiWikiImage:(NSString *)imageUrl
{
    NSString *url = [imageUrl stringByRemovingPercentEncoding];
    NSString *imageHiResUrl = [url stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *imageFileName = url.lastPathComponent;
    NSString *imageName = imageFileName.stringByDeletingPathExtension;
    NSString *imageStubUrl = [NSString stringWithFormat:@"%@%@%i", imageHiResUrl, @"?width=", THUMB_SIZE];
    return [[WikiImage alloc] initWithWikiMediaTag:imageFileName
                                           imageName:imageName
                                        imageStubUrl:imageStubUrl
                                       imageHiResUrl:imageHiResUrl];
}

- (WikiImage *)getWikiImage:(NSString *)imageFileName
{
    NSString *imageName = [imageFileName stringByRemovingPercentEncoding];
    imageFileName = [imageName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    imageFileName = [imageName stringByReplacingOccurrencesOfString:@"File:" withString:@""];
    
    NSRange dotRange = [imageName rangeOfString:@"." options:NSBackwardsSearch];
    if (dotRange.location != NSNotFound)
        imageName = [imageName substringToIndex:dotRange.location];
    
    NSString *urlSafeFileName = [imageFileName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];

    NSString *imageHiResUrl = [NSString stringWithFormat:@"%@%@", IMAGE_BASE_URL, urlSafeFileName];
    NSString *imageStubUrl = [NSString stringWithFormat:@"%@%@%@%i", IMAGE_BASE_URL, urlSafeFileName, WIKIMEDIA_WIDTH, THUMB_SIZE];

    return [[WikiImage alloc] initWithWikiMediaTag:urlSafeFileName imageName:imageName imageStubUrl:imageStubUrl imageHiResUrl:imageHiResUrl];
}

- (void)runCallback:(NSMutableArray<AbstractCard *> *)cards
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_addOtherImagesFunction)
            _addOtherImagesFunction(cards);
    });
}

//
// if
// USE_OSMAND_WIKI_API == NO
//

- (void)readyToAddWithType:(EOAWikiImageType)type cards:(NSMutableArray<AbstractCard *> *)cards
{
    [_cardTypesReady addObject:@(type)];
    if (_cardTypesReady.count == cardTypes.count && _addOtherImagesFunction)
    {
        if (_foundImages.count > 0)
        {
            NSMutableSet<NSString *> *filteredImages = [NSMutableSet setWithArray:[_foundImages valueForKey:@"imageStubUrl"]];
            for (WikiImage *image in _foundImages)
            {
                if (filteredImages.count == 0)
                    break;
                if ([filteredImages containsObject:image.imageStubUrl])
                {
                    [filteredImages removeObject:image.imageStubUrl];
                    WikiImageCard *card = [[WikiImageCard alloc] initWithWikiImage:image type:@"wikimedia-photo"];
                    if (card)
                        [cards addObject:card];
                }
            }
        }
        _foundImages = nil;
        _cardTypesReady = nil;
        _addOtherImagesFunction(cards);
    }
}

- (void)addWikidataImageCards:(NSString *)wikidataId cards:(NSMutableArray<AbstractCard *> *)cards
{
    NSString *safeWikidataTagContent = [wikidataId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *urlObj = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@%@", WIKIDATA_API_ENDPOINT, WIKIDATA_ACTION, safeWikidataTagContent, FORMAT_JSON]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data && !error)
            {
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (!error && jsonDict)
                {
                    try {
                        NSArray *records = jsonDict[@"claims"][@"P18"];
                        if (records && records.count > 0)
                        {
                            NSString *imageName = records.firstObject[@"mainsnak"][@"datavalue"][@"value"];
                            if (imageName)
                                [_foundImages addObject:[self getWikiImage:imageName]];
                        }
                    }
                    catch(NSException *e)
                    {
                        NSLog(@"Wikidata photos json serialising error: %@", e.reason);
                    }
                }
                else
                {
                    NSLog(@"Wikidata photos error parsing json: %@", error);
                }
            }
            else
            {
                NSLog(@"Wikidata photos error: %@", error);
            }
        }
        else
        {
            NSLog(@"Error retrieving Wikidata photos: %@", error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self readyToAddWithType:EOAWikiImageTypeWikidata cards:cards];
        });
    }] resume];
}

- (void)addWikimediaCardsFromCategory:(NSString *)categoryName
                                cards:(NSMutableArray<AbstractCard *> *)cards
                                depth:(NSInteger)depth
                             prepared:(BOOL)prepared
{
    __block BOOL ready = prepared;
    NSString *url = [NSString stringWithFormat:@"%@%@%@%@%@%@", WIKIMEDIA_API_ENDPOINT, WIKIMEDIA_ACTION, WIKIMEDIA_CATEGORY, categoryName, CM_LIMIT, FORMAT_JSON];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *urlObj = [NSURL URLWithString:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data && !error)
            {
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (!error && jsonDict)
                {
                    try {
                        NSDictionary *cms = jsonDict[@"query"][@"categorymembers"];
                        NSMutableArray<NSString *> *subCategories = [NSMutableArray array];
                        for (NSDictionary *cm in cms)
                        {
                            NSString *memberTitle = cm[@"title"];
                            if (memberTitle)
                            {
                                if ([memberTitle hasPrefix:WIKIMEDIA_CATEGORY])
                                {
                                    ready = NO;
                                    [subCategories addObject:memberTitle];
                                }
                                else
                                {
                                    [_foundImages addObject:[self getWikiImage:memberTitle]];
                                }
                            }
                        }
                        if (depth < DEPT_CAT_LIMIT)
                        {
                            for (NSInteger i = 0; i < subCategories.count; i ++)
                            {
                                NSString *subCategory = subCategories[i];
                                [self addWikimediaCardsFromCategory:subCategory
                                                              cards:cards
                                                              depth:depth + 1
                                                           prepared:i == subCategories.count - 1];
                            }
                        }
                    }
                    catch(NSException *e)
                    {
                        NSLog(@"Wikimedia photos json serialising error: %@", e.reason);
                    }
                }
                else
                {
                    NSLog(@"Wikimedia photos error parsing json: %@", error);
                }
            }
            else
            {
                NSLog(@"Wikimedia photos error: %@", error);
            }
        }
        else
        {
            NSLog(@"Error retrieving Wikimedia photos: %@", error);
        }
        if (ready)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self readyToAddWithType:EOAWikiImageTypeWikimedia cards:cards];
            });
        }
    }] resume];
}

@end
