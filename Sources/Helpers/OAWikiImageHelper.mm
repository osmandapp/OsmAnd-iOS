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
        wikimediaTagContent = poi.values[@"wikimedia_commons"];
        wikidataTagContent = poi.values[@"wikidata"];
    }
    _wikidataCardsReady = NO;
    _wikimediaCardsReady = NO;
    [self addWikimediaCards:wikimediaTagContent cards:cards rowInfo:nearbyImagesRowInfo];
    [self addWikidataCards:wikidataTagContent cards:cards rowInfo:nearbyImagesRowInfo];
}

- (OAWikiImage *)getWikiImage:(NSString *)imageFileName
{
    NSString *imageName = [imageFileName stringByRemovingPercentEncoding];
    imageFileName = [imageName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    imageName = [imageName substringToIndex:[imageName lastIndexOf:@"."]];

    NSString *hash = [CocoaSecurity md5:imageFileName].hexLower;
    NSString *hashFirstPart = [hash substringWithRange:NSMakeRange(0, 1)];
    NSString *hashSecondPart = [hash substringWithRange:NSMakeRange(0, 2)];

    NSString *imageHiResUrl = [NSString stringWithFormat:@"%@%@/%@/%@", IMAGE_BASE_URL, hashFirstPart, hashSecondPart, imageFileName];
    NSString *imageStubUrl = [NSString stringWithFormat:@"%@thumb/%@/%@/%@/%ipx-%@", IMAGE_BASE_URL, hashFirstPart, hashSecondPart, imageFileName, THUMB_SIZE, imageFileName];

    return [[OAWikiImage alloc] initWithWikiMediaTag:imageFileName imageName:imageName imageStubUrl:imageStubUrl imageHiResUrl:imageHiResUrl];
}

- (void)addWikidataCards:(NSString *)wikidataTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    if (wikidataTagContent && [wikidataTagContent hasPrefix:WIKIDATA_PREFIX])
    {
        NSURL *urlObj = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@%@%@", WIKIDATA_API_ENDPOINT, WIKIDATA_ACTION, wikidataTagContent, FORMAT_JSON]];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
            dispatch_async(dispatch_get_main_queue(), ^{
                if (resultCard)
                    [cards addObject:resultCard];
                _wikidataCardsReady = YES;
                if (_wikimediaCardsReady)
                    _addOtherImagesFunction(cards);
            });
        }] resume];
    }
    else
    {
        _wikidataCardsReady = YES;
        if (_wikimediaCardsReady)
            _addOtherImagesFunction(cards);
    }
}

- (void)addWikimediaCards:(NSString *)wikiMediaTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
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
        NSString *url = [NSString stringWithFormat:@"%@%@%@%@%@", WIKIMEDIA_API_ENDPOINT, WIKIMEDIA_ACTION, wikiMediaTagContent, CM_LIMIT, FORMAT_JSON];
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
                                OAWikiImageCard *card = [[OAWikiImageCard alloc] initWithWikiImage:[self getWikiImage:imageName] type:@"wikimedia-photo"];
                                if (card)
                                    [resultCards addObject:card];
                            }
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [cards addObjectsFromArray:resultCards];
                _wikimediaCardsReady = YES;
                if (_wikidataCardsReady)
                    _addOtherImagesFunction(cards);
            });
        }] resume];
    }
    else
    {
        _wikimediaCardsReady = YES;
        if (_wikidataCardsReady)
            _addOtherImagesFunction(cards);
    }
}

@end
