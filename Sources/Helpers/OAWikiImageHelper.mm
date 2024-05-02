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

typedef NS_ENUM(NSInteger, EOAWikiImageType) {
    EOAWikiImageTypeWikimedia = 0,
    EOAWikiImageTypeWikidata,
    EOAWikiImageTypeWikipedia,
};

static NSArray<NSNumber *> *allCardTypes = @[@(EOAWikiImageTypeWikimedia), @(EOAWikiImageTypeWikidata), @(EOAWikiImageTypeWikipedia)];

@interface OAWikiImageHelper ()

typedef void(^OAWikiImageHelperOtherImages)(NSMutableArray<OAAbstractCard *> *cards);
@property OAWikiImageHelperOtherImages addOtherImagesFunction;

@end

@implementation OAWikiImageHelper
{
    NSMutableArray<NSNumber *> *_cardsTypeReady;
    NSMutableArray<OAWikiImage *> *_foundImages;
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
    _cardsTypeReady = [NSMutableArray array];
    _foundImages = [NSMutableArray array];
    if ([targetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = targetObj;
        [self addImageCards:poi.values[WIKIMEDIA_COMMONS_TAG] type:EOAWikiImageTypeWikimedia cards:cards];
        [self addImageCards:poi.values[WIKIDATA_TAG] type:EOAWikiImageTypeWikidata cards:cards];
        [self addImageCards:poi.values[WIKIPEDIA_TAG] type:EOAWikiImageTypeWikipedia cards:cards];
    }
    else if (_addOtherImagesFunction)
    {
        _addOtherImagesFunction(cards);
    }
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

- (void)readyToAddWithType:(EOAWikiImageType)type cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    [_cardsTypeReady addObject:@(type)];
    if (_cardsTypeReady.count == allCardTypes.count && _addOtherImagesFunction)
    {
        if (_foundImages.count > 0)
        {
            NSMutableSet<NSString *> *filteredImages = [NSMutableSet setWithArray:[_foundImages valueForKey:@"imageStubUrl"]];
            for (OAWikiImage *image in _foundImages)
            {
                if (filteredImages.count == 0)
                    break;
                if ([filteredImages containsObject:image.imageStubUrl])
                {
                    [filteredImages removeObject:image.imageStubUrl];
                    OAWikiImageCard *card = [[OAWikiImageCard alloc] initWithWikiImage:image type:@"wikimedia-photo"];
                    if (card)
                        [cards addObject:card];
                }
            }
        }
        _foundImages = nil;
        _cardsTypeReady = nil;
        _addOtherImagesFunction(cards);
    }
}

- (void)addOsmandAPIImageList:(NSString *)tagContent
                         type:(EOAWikiImageType)type
                        cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    NSString *tag = @"";
    switch (type)
    {
        case EOAWikiImageTypeWikimedia:
            tag = @"category=";
            break;
        case EOAWikiImageTypeWikidata:
            tag = @"article=";
            break;
        case EOAWikiImageTypeWikipedia:
            tag = @"wiki=";
            break;
    }
    NSString *url = [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, tag, tagContent];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
                        [_foundImages addObject:[self getOsmandApiWikiImage:image]];
                    }
                }
            }
        }
        else
        {
            NSLog(@"Error retrieving Wikimedia photos (OsmandApi): %@", error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self readyToAddWithType:type cards:cards];
        });
    }] resume];
}

- (void)addImageCards:(NSString *)tagContent
                 type:(EOAWikiImageType)type
                cards:(NSMutableArray<OAAbstractCard *> *)cards
{
    if (tagContent)
    {
        if ([tagContent hasPrefix:WIKIMEDIA_FILE])
        {
            NSString *fileName = [tagContent stringByReplacingOccurrencesOfString:WIKIMEDIA_FILE withString:@""];
            [_foundImages addObject:[self getWikiImage:fileName]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self readyToAddWithType:type cards:cards];
            });
        }
        else if ([tagContent hasPrefix:WIKIMEDIA_CATEGORY])
        {
            NSString *categoryName = [tagContent stringByReplacingOccurrencesOfString:WIKIMEDIA_CATEGORY withString:@""];
            if (USE_OSMAND_WIKI_API)
                [self addOsmandAPIImageList:categoryName type:type cards:cards];
            else
                [self addWikimediaCardsFromCategory:categoryName type:type cards:cards depth:0 prepared:YES];
        }
        else if (USE_OSMAND_WIKI_API)
        {
            [self addOsmandAPIImageList:tagContent type:type cards:cards];
        }
        else if ([tagContent hasPrefix:WIKIDATA_PREFIX])
        {
            NSString *safeWikidataTagContent = [tagContent stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL *urlObj = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@%@%@", WIKIDATA_API_ENDPOINT, WIKIDATA_ACTION, safeWikidataTagContent, FORMAT_JSON]];
            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [[session dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
                                        [_foundImages addObject:[self getWikiImage:imageName]];
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
                    [self readyToAddWithType:type cards:cards];
                });
            }] resume];
        }
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self readyToAddWithType:type cards:cards];
        });
    }
}

- (void)addWikimediaCardsFromCategory:(NSString *)categoryName
                                 type:(EOAWikiImageType)type
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
                                                           type:type
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
                [self readyToAddWithType:type cards:cards];
            });
        }
    }] resume];
}

@end
