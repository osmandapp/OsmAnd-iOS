//
//  OAWikiImageHelper.mm
//  OsmAnd
//
//  Created by Skalii on 05.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAWikiImageHelper.h"
#import "OAAppSettings.h"
#import "OATargetInfoViewController.h"
#import "OAPOI.h"
#import "OsmAnd_Maps-Swift.h"

typedef NS_ENUM(NSInteger, EOAWikiImageType) {
    EOAWikiImageTypeWikimedia = 0,
    EOAWikiImageTypeWikidata
};

static NSArray<NSNumber *> *cardTypes = @[@(EOAWikiImageTypeWikimedia), @(EOAWikiImageTypeWikidata)];

static NSString * const kWikipediaShortLink = @".wikipedia.org/wiki/";

static NSString *OAEncodedWikiQueryValue(NSString *value)
{
    NSMutableCharacterSet *allowedCharacters = [NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];
    [allowedCharacters removeCharactersInString:@"&=+?#"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

static NSString *OANormalizedWikiMediaTag(NSString *tag)
{
    NSString *decodedTag = tag.stringByRemovingPercentEncoding ?: tag;
    return [[decodedTag stringByReplacingOccurrencesOfString:@"_" withString:@" "] lowercaseString];
}

static BOOL OAIsWikiFileMetadataMissing(NSData *data, NSString *fileName)
{
    if (!data || fileName.length == 0)
        return NO;

    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSArray *images = [json isKindOfClass:NSDictionary.class] ? json[@"features-v2"] : nil;
    if (![images isKindOfClass:NSArray.class])
        return NO;

    // NSURLComponents has already decoded the file query value once.
    NSString *normalizedFileName = [[fileName stringByReplacingOccurrencesOfString:@"_" withString:@" "] lowercaseString];
    for (NSDictionary *image in images)
    {
        if (![image isKindOfClass:NSDictionary.class])
            continue;
        NSString *imageURL = image[@"image"];
        if (![imageURL isKindOfClass:NSString.class]
            || ![OANormalizedWikiMediaTag(imageURL.lastPathComponent) isEqualToString:normalizedFileName])
            continue;

        for (NSString *key in @[@"date", @"author", @"license", @"description"])
        {
            NSString *value = image[key];
            if ([value isKindOfClass:NSString.class] && value.length > 0)
                return NO;
        }
        return YES;
    }
    return YES;
}

static NSString *OANormalizedWikipediaTitle(NSString *language, NSString *title)
{
    if (language.length == 0 || title.length == 0)
        return nil;

    NSString *languagePrefix = [language stringByAppendingString:@":"];
    if ([title rangeOfString:languagePrefix options:NSCaseInsensitiveSearch].location == 0
        || [title indexOf:kWikipediaShortLink] > 0)
    {
        return title;
    }
    return [NSString stringWithFormat:@"%@:%@", language, title];
}

static void OAAddWikipediaLanguageCandidates(NSMutableOrderedSet<NSString *> *languages, NSString *language)
{
    NSString *normalizedLanguage = [[language stringByReplacingOccurrencesOfString:@"_" withString:@"-"] lowercaseString];
    if (normalizedLanguage.length == 0)
        return;

    [languages addObject:normalizedLanguage];
    NSRange separatorRange = [normalizedLanguage rangeOfString:@"-"];
    if (separatorRange.location != NSNotFound)
        [languages addObject:[normalizedLanguage substringToIndex:separatorRange.location]];
}

static NSString *OAExtractWikipediaTitle(MutableOrderedDictionary<NSString *, NSString *> *values)
{
    NSString *directTitle = values[WIKIPEDIA_TAG];
    if (directTitle.length > 0)
        return directTitle;

    NSString *localizedPrefix = [WIKIPEDIA_TAG stringByAppendingString:@":"];
    NSMutableOrderedSet<NSString *> *preferredLanguages = [NSMutableOrderedSet orderedSet];
    OAAddWikipediaLanguageCandidates(preferredLanguages, [OAAppSettings sharedManager].settingPrefMapLanguage.get);
    for (NSString *language in NSLocale.preferredLanguages)
        OAAddWikipediaLanguageCandidates(preferredLanguages, language);
    [preferredLanguages addObject:@"en"];

    for (NSString *language in preferredLanguages)
    {
        NSString *title = values[[localizedPrefix stringByAppendingString:language]];
        NSString *normalizedTitle = OANormalizedWikipediaTitle(language, title);
        if (normalizedTitle.length > 0)
            return normalizedTitle;
    }

    for (NSString *key in values.allKeys)
    {
        if (![key hasPrefix:localizedPrefix] || key.length == localizedPrefix.length)
            continue;

        NSString *title = values[key];
        NSString *language = [key substringFromIndex:localizedPrefix.length];
        NSString *normalizedTitle = OANormalizedWikipediaTitle(language, title);
        if (normalizedTitle.length > 0)
            return normalizedTitle;
    }
    return nil;
}

static NSURLRequest *OARequestForLegacyWikiCacheKey(NSURLRequest *request, BOOL removeLocalizedWikipedia)
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *legacyItems = [NSMutableArray array];
    BOOL hasLegacySource = NO;
    BOOL didRemoveNewParameter = NO;
    for (NSURLQueryItem *item in components.queryItems)
    {
        BOOL shouldRemoveItem = [item.name isEqualToString:@"file"]
            || (removeLocalizedWikipedia && [item.name isEqualToString:@"wiki"]);
        if (shouldRemoveItem)
        {
            didRemoveNewParameter = YES;
            continue;
        }
        if ([item.name isEqualToString:@"article"]
            || [item.name isEqualToString:@"category"]
            || [item.name isEqualToString:@"wiki"])
        {
            hasLegacySource = YES;
        }
        [legacyItems addObject:item];
    }
    if (!didRemoveNewParameter || !hasLegacySource)
        return nil;
    components.queryItems = legacyItems;
    return [NSURLRequest requestWithURL:components.URL
                            cachePolicy:request.cachePolicy
                        timeoutInterval:request.timeoutInterval];
}

@interface OAWikiImageHelper ()

typedef void(^OAWikiImageHelperOtherImages)(NSMutableArray<AbstractCard *> *cards, BOOL requestFailed);
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

- (void)sendNearbyWikiImagesRequest:(OAAmenityInfoRow *)nearbyImagesRowInfo
                          targetObj:(id)targetObj
                            session:(nullable NSURLSession *)session
           addOtherImagesOnComplete:(void (^)(NSMutableArray <AbstractCard *> *cards, BOOL requestFailed))addOtherImagesOnComplete
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
        NSString *wikiFileName = @"";
        NSString *url = @"";
        NSArray<NSString *> *keys = poi.values.allKeys;
        
        if ([keys containsObject:WIKIMEDIA_COMMONS_TAG])
        {
            NSString *wikimediaCommons = poi.values[WIKIMEDIA_COMMONS_TAG];
            if ([wikimediaCommons hasPrefix:WIKIMEDIA_FILE])
            {
                wikiFileName = [wikimediaCommons substringFromIndex:WIKIMEDIA_FILE.length];
                WikiImage *wikiImage = [self getWikiImage:wikiFileName];
                WikiImageCard *card = [[WikiImageCard alloc] initWithWikiImage:wikiImage type:@"wikimedia-photo"];
                if (card)
                    [cards addObject:card];
            }
            else if ([wikimediaCommons hasPrefix:WIKIMEDIA_CATEGORY])
            {
                wikiCategory = [wikimediaCommons stringByReplacingOccurrencesOfString:WIKIMEDIA_CATEGORY withString:@""];
                url = [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"category=", OAEncodedWikiQueryValue(wikiCategory)];
            }
        }
        if ([keys containsObject:WIKIDATA_TAG])
        {
            wikidataId = poi.values[WIKIDATA_TAG];
            NSString *encodedWikidataId = OAEncodedWikiQueryValue(wikidataId);
            url = url.length == 0
                ? [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"article=", encodedWikidataId]
                : [url stringByAppendingFormat:@"&%@%@", @"article=", encodedWikidataId];
        }
        NSString *directWikiTitle = poi.values[WIKIPEDIA_TAG];
        NSString *wikiTitle = OAExtractWikipediaTitle(poi.values);
        BOOL usesLocalizedWikipediaTag = directWikiTitle.length == 0 && wikiTitle.length > 0;
        if (wikiTitle.length > 0)
        {
            NSInteger urlInd = [wikiTitle indexOf:kWikipediaShortLink];
            if (urlInd > 0)
            {
                NSString *prefix = [wikiTitle substringToIndex:urlInd];
                NSString *lang = [[prefix substringFromIndex:[prefix lastIndexOf:@"/"] + 1] stringByReplacingOccurrencesOfString:@"/" withString:@""];
                NSString *title = [wikiTitle substringFromIndex:urlInd + kWikipediaShortLink.length];
                wikiTitle = [NSString stringWithFormat:@"%@:%@", lang, title.stringByRemovingPercentEncoding ?: title];
            }

            NSString *encodedWikiTitle = OAEncodedWikiQueryValue(wikiTitle);
            url = url.length == 0
                ? [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"wiki=", encodedWikiTitle]
                : [url stringByAppendingFormat:@"&%@%@", @"wiki=", encodedWikiTitle];
        }

        if (wikiFileName.length > 0)
        {
            NSString *decodedWikiFileName = wikiFileName.stringByRemovingPercentEncoding ?: wikiFileName;
            NSString *encodedWikiFileName = OAEncodedWikiQueryValue(decodedWikiFileName);
            url = url.length == 0
                ? [NSString stringWithFormat:@"%@%@%@", OSMAND_API_ENDPOINT, @"file=", encodedWikiFileName]
                : [url stringByAppendingFormat:@"&%@%@", @"file=", encodedWikiFileName];
        }

        if (USE_OSMAND_WIKI_API)
        {
            if (url.length > 0)
            {
                url = [url stringByAppendingString:@"&addMetaData=true"];
                [self addOsmandAPIImageList:url
          removeLocalizedWikipediaFromLegacyKey:usesLocalizedWikipediaTag
                                      cards:cards
                                    session:session];
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

- (void)addOsmandAPIImageList:(NSString *)url
removeLocalizedWikipediaFromLegacyKey:(BOOL)removeLocalizedWikipediaFromLegacyKey
                        cards:(NSMutableArray<AbstractCard *> *)cards
                      session:(nullable NSURLSession *)session
{
    NSURL *urlObj = [NSURL URLWithString:url];
    NSString *key = [URLSessionConfigProvider onlineAndMapillaryPhotosAPIKey];
    NSURLSession *urlSession = session ?: [URLSessionManager sessionFor:key];

    NSURLRequest *request = [NSURLRequest requestWithURL:urlObj
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:30];
    NSString *fileName = nil;
    for (NSURLQueryItem *item in [NSURLComponents componentsWithURL:urlObj resolvingAgainstBaseURL:NO].queryItems)
    {
        if ([item.name isEqualToString:@"file"])
        {
            fileName = item.value;
            break;
        }
    }
    NSCachedURLResponse *existingCached = [URLSessionManager cachedResponseFor:request sessionKey:key];
    // The server may legitimately have no metadata for this file, so refresh an old cache entry only once.
    BOOL metadataAlreadyChecked = [existingCached.userInfo[[URLSessionManager wikiFileMetadataCheckedKey]] boolValue];
    BOOL refreshIncompleteMetadata = !metadataAlreadyChecked
        && OAIsWikiFileMetadataMissing(existingCached.data, fileName);
    BOOL refreshExpiredCache = existingCached && [URLSessionManager isExpiredCachedResponse:existingCached];
    // Only a cache miss or a forced reload should extend the cache lifetime.
    BOOL fetchFreshResponse = !existingCached || refreshIncompleteMetadata || refreshExpiredCache;
    NSURLRequest *requestForTask = (refreshIncompleteMetadata || refreshExpiredCache)
        ? [NSURLRequest requestWithURL:urlObj cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30]
        : request;
    __weak __typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:requestForTask
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        if (error && error.code == NSURLErrorCancelled)
            return;

        void (^completeWithoutWikiData)(void) = ^{
            [strongSelf runCallback:cards requestFailed:YES];
        };
        
        NSData *effectiveData = data;

        if ((!data || !response) && [ErrorHelper isInternetConnectionError:error])
        {
            NSCachedURLResponse *cached = existingCached ?: [URLSessionManager cachedResponseFor:request sessionKey:key];
            if (cached)
            {
                effectiveData = cached.data;
            }
            else
            {
                NSURLRequest *legacyRequest = OARequestForLegacyWikiCacheKey(request, removeLocalizedWikipediaFromLegacyKey);
                NSCachedURLResponse *legacyCached = legacyRequest
                    ? [URLSessionManager cachedResponseFor:legacyRequest sessionKey:key]
                    : nil;
                if (legacyCached)
                {
                    effectiveData = legacyCached.data;
                }
                else
                {
                    completeWithoutWikiData();
                    return;
                }
            }
        }

        if (!effectiveData)
        {
            NSLog(@"[ERROR] addOsmandAPIImageList effectiveData is nil, cannot parse JSON.");
            completeWithoutWikiData();
            return;
        }

        NSMutableArray<AbstractCard *> *localCards = [NSMutableArray array];

        NSError *jsonError = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:effectiveData options:NSJSONReadingAllowFragments error:&jsonError];
        NSArray *images = nil;
        if (!jsonError && [jsonDict isKindOfClass:[NSDictionary class]])
        {
            images = jsonDict[@"features-v2"];
            if ([images isKindOfClass:[NSArray class]])
            {
                for (NSDictionary *dic in images)
                {
                    if ([dic isKindOfClass:[NSDictionary class]] && dic[@"image"])
                    {
                        WikiImage *wikiImage = [strongSelf getOsmandApiWikiImage:dic[@"image"]];
                        [wikiImage parseMetaDataWith:dic];
                        if (wikiImage)
                        {
                            WikiImageCard *card = [[WikiImageCard alloc] initWithWikiImage:wikiImage type:@"wikimedia-photo"];
                            if (card)
                            {
                                [localCards addObject:card];
                            }
                        }
                    }
                }
            }
        }
        else
        {
            NSLog(@"JSON parsing error: %@", jsonError ?: @"unknown error");
        }

        BOOL isSuccessfulNetworkResponse = fetchFreshResponse && data != nil
            && [response isKindOfClass:NSHTTPURLResponse.class]
            && ((NSHTTPURLResponse *)response).statusCode == 200;
        if (isSuccessfulNetworkResponse && [images isKindOfClass:NSArray.class])
        {
            [URLSessionManager storeResponse:response
                                       data:data
                                        for:request
                                 sessionKey:key
                     wikiFileMetadataChecked:fileName.length > 0];
        }

        @synchronized(cards) {
            for (WikiImageCard *newCard in localCards)
            {
                NSUInteger existingIndex = [cards indexOfObjectPassingTest:^BOOL(AbstractCard *existingCard, NSUInteger idx, BOOL *stop) {
                    if (![existingCard isKindOfClass:WikiImageCard.class])
                        return NO;
                    WikiImage *existingImage = ((WikiImageCard *)existingCard).wikiImage;
                    return [OANormalizedWikiMediaTag(existingImage.wikiMediaTag)
                            isEqualToString:OANormalizedWikiMediaTag(newCard.wikiImage.wikiMediaTag)];
                }];
                if (existingIndex == NSNotFound)
                    [cards addObject:newCard];
                else
                    [cards replaceObjectAtIndex:existingIndex withObject:newCard];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf runCallback:cards];
        });
    }];

    [task resume];
}

- (WikiImage *)getOsmandApiWikiImage:(NSString *)imageUrl
{
    NSString *imageHiResUrl = [imageUrl stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *imageFileName = imageHiResUrl.lastPathComponent;
    NSString *decodedImageFileName = imageFileName.stringByRemovingPercentEncoding ?: imageFileName;
    NSString *imageName = decodedImageFileName.stringByDeletingPathExtension;
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
    [self runCallback:cards requestFailed:NO];
}

- (void)runCallback:(NSMutableArray<AbstractCard *> *)cards requestFailed:(BOOL)requestFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_addOtherImagesFunction)
            _addOtherImagesFunction(cards, requestFailed);
    });
}

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
        _addOtherImagesFunction(cards, NO);
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
