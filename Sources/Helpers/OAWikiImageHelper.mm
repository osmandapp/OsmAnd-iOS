//
//  OAWikiImageHelper.mm
//  OsmAnd
//
//  Created by Skalii on 05.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <CocoaSecurity.h>
#import "OAWikiImageHelper.h"
#import "OAImageCard.h"
#import "OAWikiImageCard.h"
#import "OATargetInfoViewController.h"
#import "OANoImagesCard.h"
#import "OACollapsableCardsView.h"
#import "OAPOI.h"
#import "OAAbstractCard.h"

@interface OAWikiImageHelper ()

typedef void(^OAWikiImageHelperOtherImages)(NSMutableArray<OAAbstractCard *> *cards);
@property OAWikiImageHelperOtherImages addOtherImagesFunction;

@end

@implementation OAWikiImageHelper
{
    BOOL _wikidataCardsReady;
    BOOL _wikimediaCardsReady;
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

- (void)sendNearbyWikiImagesRequest:(OARowInfo *)nearbyImagesRowInfo targetObj:(id)targetObj addOtherImagesOnComplete:(void (^)(NSMutableArray <OAAbstractCard *> *cards))addOtherImagesOnComplete;
{
    if (!nearbyImagesRowInfo)
        return;

    _addOtherImagesFunction = addOtherImagesOnComplete;
    NSMutableArray <OAAbstractCard *> *cards = [NSMutableArray new];
    NSString *wikimediaTagContent = nil;
    NSString *wikidataTagContent = nil;
    if ([targetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = targetObj;
        wikimediaTagContent = poi.values[WIKIMEDIA_COMMONS_TAG];
        wikidataTagContent = poi.values[WIKIDATA_TAG];
    }
    _wikidataCardsReady = NO;
    _wikimediaCardsReady = NO;
    [self addWikimediaCards:wikimediaTagContent cards:cards];
    [self addWikidataCards:wikidataTagContent cards:cards];
}

- (OAWikiImage *)getOsmandApiWikiImage:(NSString *)imageUrl
{
    NSString *url = [imageUrl stringByRemovingPercentEncoding];
    NSString *imageHiResUrl = [url stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *imageFileName = url.lastPathComponent;
    NSString *imageName = imageFileName.stringByDeletingPathExtension;
    NSString *imageStubUrl = [NSString stringWithFormat:@"%@%@%i", imageHiResUrl, @"?width=", THUMB_SIZE];
    return [[OAWikiImage alloc] initWithWikiMediaTag:imageFileName
                                           imageName:imageName
                                        imageStubUrl:imageStubUrl
                                       imageHiResUrl:imageHiResUrl];
}

- (OAWikiImage *)getWikiImage:(NSString *)imageFileName
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

    return [[OAWikiImage alloc] initWithWikiMediaTag:urlSafeFileName imageName:imageName imageStubUrl:imageStubUrl imageHiResUrl:imageHiResUrl];
}

- (void)addOsmandAPIWikimediaImageListByCategory:(NSString *)categoryName
                                cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    NSString *url = [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"category=", categoryName];
    [self addOsmandAPIImageList:url cards:cards byCategory:YES];
}

- (void)addOsmandAPIWikidataImageList:(NSString *)wikidataTagContent
                                cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    NSString *url = [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"article=", wikidataTagContent];
    [self addOsmandAPIImageList:url cards:cards byCategory:NO];
}

- (void)addOsmandAPIImageList:(NSString *)url
                        cards:(NSMutableArray<OAAbstractCard *> *)cards
                   byCategory:(BOOL)byCategory
{
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSMutableArray<OAAbstractCard *> *resultCards = [NSMutableArray array];
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data)
            {
                NSError *error;
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                NSArray<NSString *> *images = jsonDict[@"features"];
                if (!error && images)
                {
                    for (NSString *image in images)
                    {
                        OAWikiImageCard *card = [[OAWikiImageCard alloc] initWithWikiImage:[self getOsmandApiWikiImage:image] type:@"wikimedia-photo" wikimediaCategory:NO];
                        if (card)
                            [resultCards addObject:card];
                    }
                }
            }
        }
        else
        {
            NSLog(@"Error retrieving Wikimedia photos (OsmandApi): %@", error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [cards addObjectsFromArray:resultCards];
            if (byCategory)
            {
                _wikimediaCardsReady = YES;
                if (_wikidataCardsReady)
                    _addOtherImagesFunction(cards);
            }
            else
            {
                _wikidataCardsReady = YES;
                if (_wikimediaCardsReady)
                    _addOtherImagesFunction(cards);
            }
        });
    }] resume];
}


- (void)addWikidataCards:(NSString *)wikidataTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    if (wikidataTagContent)
    {
        if (USE_OSMAND_WIKI_API)
        {
            [self addOsmandAPIWikidataImageList:wikidataTagContent cards:cards];
        }
        else if ([wikidataTagContent hasPrefix:WIKIDATA_PREFIX])
        {
            NSString *safeWikidataTagContent = [wikidataTagContent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL *urlObj = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@%@%@", WIKIDATA_API_ENDPOINT, WIKIDATA_ACTION, safeWikidataTagContent, FORMAT_JSON]];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                OAWikiImageCard *resultCard = nil;
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
                                        resultCard = [[OAWikiImageCard alloc] initWithWikiImage:[self getWikiImage:imageName] type:@"wikidata-photo"];
                                }
                            }
                            catch(NSException *e)
                            {
                                NSLog(@"Wikidata image json serialising error");
                            }
                        }
                    }
                }
                else
                {
                    NSLog(@"Error retrieving Wikidata photos: %@", error);
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (resultCard)
                        [cards addObject:resultCard];
                    _wikidataCardsReady = YES;
                    if (_wikimediaCardsReady)
                        _addOtherImagesFunction(cards);
                });
            }] resume];
        }
    }
    else
    {
        _wikidataCardsReady = YES;
        if (_wikimediaCardsReady)
            _addOtherImagesFunction(cards);
    }
}

- (void)addWikimediaCards:(NSString *)wikiMediaTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    if (wikiMediaTagContent && [wikiMediaTagContent hasPrefix:WIKIMEDIA_FILE])
    {
        NSString *fileName = [wikiMediaTagContent stringByReplacingOccurrencesOfString:WIKIMEDIA_FILE withString:@""];
        OAWikiImageCard *card = [[OAWikiImageCard alloc] initWithWikiImage:[self getWikiImage:fileName] type:@"wikimedia-photo"];
        if (card)
        {
            [cards addObject:card];
            _wikimediaCardsReady = YES;
            if (_wikidataCardsReady)
                _addOtherImagesFunction(cards);
        }
    }
    else if (wikiMediaTagContent && [wikiMediaTagContent hasPrefix:WIKIMEDIA_CATEGORY])
    {
        NSString *categoryName = [wikiMediaTagContent stringByReplacingOccurrencesOfString:WIKIMEDIA_CATEGORY withString:@""];
        if (USE_OSMAND_WIKI_API)
            [self addOsmandAPIWikimediaImageListByCategory:categoryName cards:cards];
        else
            [self addWikimediaCardsFromCategory:categoryName cards:cards depth:0 prepared:YES];
    }
    else
    {
        _wikimediaCardsReady = YES;
        if (_wikidataCardsReady)
            _addOtherImagesFunction(cards);
    }
}

- (void)addWikimediaCardsFromCategory:(NSString *)categoryName
                                cards:(NSMutableArray<OAAbstractCard *> *)cards
                                depth:(NSInteger)depth
                             prepared:(BOOL)prepared
{
    __block BOOL ready = prepared;
    NSString *url = [NSString stringWithFormat:@"%@%@%@%@%@%@", WIKIMEDIA_API_ENDPOINT, WIKIMEDIA_ACTION, WIKIMEDIA_CATEGORY, categoryName, CM_LIMIT, FORMAT_JSON];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSMutableArray<OAAbstractCard *> *resultCards = [NSMutableArray array];
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data)
            {
                NSError *error;
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                NSDictionary *cms = jsonDict[@"query"][@"categorymembers"];
                if (!error && cms)
                {
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
                                OAWikiImageCard *card = [[OAWikiImageCard alloc] initWithWikiImage:[self getWikiImage:memberTitle] type:@"wikimedia-photo" wikimediaCategory:YES];
                                if (card)
                                    [resultCards addObject:card];
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
            }
        }
        else
        {
            NSLog(@"Error retrieving Wikimedia photos: %@", error);
        }
        if (ready)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [cards addObjectsFromArray:resultCards];
                _wikimediaCardsReady = YES;
                if (_wikidataCardsReady)
                    _addOtherImagesFunction(cards);
            });
        }
    }] resume];
}

@end
