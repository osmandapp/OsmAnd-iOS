//
//  OASearchPhrase.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/SearchPhrase.java
//  git revision aea6f3ff8842b91fda4b471e24015e4142c52d13

#import "OASearchPhrase.h"
#import "OASearchWord.h"
#import "OASearchSettings.h"
#import "OAUtilities.h"
#import "QuadRect.h"
#import "OACollatorStringMatcher.h"
#import "OsmAndApp.h"
#import "OAPOIBaseType.h"
#import "OAUtilities.h"
#import "OALocationParser.h"
#import "OAAbbreviations.h"
#import "OAMapUtils.h"
#import "OAArabicNormalizer.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Data/ObfMapSectionInfo.h>
#include <OsmAndCore/Search/CommonWords.h>

static NSString *DELIMITER = @" ";
static NSString *ALLDELIMITERS = @"\\s|,";
static NSString *ALLDELIMITERS_WITH_HYPHEN = @"\\s|,|-";
static NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:ALLDELIMITERS options:0 error:nil];

static NSSet<NSString *> *conjunctions;
static NSCharacterSet *allDelimitersSet;

static const int ZOOM_TO_SEARCH_POI = 16;

static NSArray<NSString *> *CHARS_TO_NORMALIZE_KEY = @[@"’", @"ʼ", @"(", @")", @"´", @"`", @"′", @"‵", @"ʹ"]; // remove () subcities
static NSArray<NSString *> *CHARS_TO_NORMALIZE_VALUE = @[@"'", @"'", @" ", @" ", @"'", @"'", @"'", @"'", @"'"];

@interface OASearchPhrase ()

@property (nonatomic) OACollatorStringMatcher *clt;
@property (nonatomic) OASearchSettings *settings;

@property (nonatomic) NSString *fileId;

// Object consists of 2 part [known + unknown]
@property (nonatomic) NSString *fullTextSearchPhrase;
@property (nonatomic) NSString *unknownSearchPhrase;

// words to be used for words span
@property (nonatomic) NSMutableArray<OASearchWord *> *words;

// Words of 2 parts
@property (nonatomic) NSString *firstUnknownSearchWord;
@property (nonatomic) NSMutableArray<NSString *> *otherUnknownWords;
@property (nonatomic) BOOL lastUnknownSearchWordComplete;

// Main unknown word used for search
@property (nonatomic) NSString *mainUnknownWordToSearch;
@property (nonatomic) BOOL mainUnknownSearchWordComplete;

// Name Searchers
@property (nonatomic) OANameStringMatcher *firstUnknownNameStringMatcher;
@property (nonatomic) OANameStringMatcher *mainUnknownNameStringMatcher;
@property (nonatomic) NSMutableArray<OANameStringMatcher *> *unknownWordsMatcher;

@property (nonatomic) QuadRect *cache1kmRect;

@property (nonatomic) OAPOIBaseType *unselectedPoiType;

@end

static NSComparator _OACommonWordsComparator = nil;

@implementation OASearchPhrase
{
    NSMutableArray<NSString *> *_indexes;
    OsmAndAppInstance _app;
    NSMapTable<NSString *, NSObject *> *_resourceLocations;
}

+ (void) initialize
{
    if (self == [OASearchPhrase class])
    {
        allDelimitersSet = [NSCharacterSet characterSetWithCharactersInString:ALLDELIMITERS];
        conjunctions = [NSSet setWithObjects:
                        // the
                        @"the",
                        @"der",
                        @"den",
                        @"die",
                        @"das",
                        @"la",
                        @"le",
                        @"el",
                        @"il",
                        // and
                        @"and",
                        @"und",
                        @"en",
                        @"et",
                        @"y",
                        @"и",
                        // Don't add short names !  issues for perfect matching "Drive A", ...
                        nil];
        _OACommonWordsComparator = ^NSComparisonResult(NSString * _Nonnull o1, NSString * _Nonnull o2)
        {
            int i1 = OsmAnd::CommonWords::getCommonSearch(QString::fromNSString([o1 lowercaseString]));
            int i2 = OsmAnd::CommonWords::getCommonSearch(QString::fromNSString([o2 lowercaseString]));
            
            if (i1 != i2)
            {
                if (i1 == -1)
                    return NSOrderedAscending;
                else if (i2 == -1)
                    return NSOrderedDescending;
                
                return [OAUtilities compareInt:i2 y:i1];
            }
            
            // compare length without numbers to not include house numbers
            return [OAUtilities compareInt:[OASearchPhrase lengthWithoutNumbers:o2] y:[OASearchPhrase lengthWithoutNumbers:o1]];
        };
    }
}

- (NSComparator) commonWordsComparator
{
    return _OACommonWordsComparator;
}

+ (OASearchPhrase *) emptyPhrase
{
    return [self emptyPhrase:nil];
}

+ (OASearchPhrase *) emptyPhrase:(OASearchSettings *)settings
{
    return [[OASearchPhrase alloc] initWithSettings:settings];
}

- (NSString *) getFileId
{
    return _fileId;
}

- (OASearchPhrase *) generateNewPhrase:(OASearchPhrase *)phrase fileId:(NSString *)fileId
{
    OASearchPhrase *nphrase = [phrase generateNewPhrase:[phrase getUnknownSearchPhrase] settings:[phrase getSettings]];
    nphrase.fileId = fileId;
    return nphrase;
}

- (OASearchPhrase *) createNewSearchPhrase:(OASearchSettings *)settings fullText:(NSString *)text foundWords:(NSMutableArray<OASearchWord *> *)foundWords textToSearch:(NSString *)textToSearch
{
    OASearchPhrase *sp = [[OASearchPhrase alloc] initWithSettings:settings];
    sp.words = foundWords;
    sp.fullTextSearchPhrase = text;
    sp.unknownSearchPhrase = textToSearch;
    sp.lastUnknownSearchWordComplete = [self isTextComplete:text];
    if ([regex matchesInString:textToSearch options:0 range:NSMakeRange(0, [textToSearch length])].count == 0)
    {
        sp.firstUnknownSearchWord = [sp.unknownSearchPhrase trim];
    }
    else
    {
        sp.firstUnknownSearchWord = @"";
        NSArray<NSString *> *ws = [textToSearch componentsSeparatedByRegex:ALLDELIMITERS];
        BOOL first = YES;
        for (NSInteger i = 0; i < ws.count; i++)
        {
            NSString *wd = [ws[i] trim];
            BOOL conjunction = [conjunctions containsObject:wd.lowerCase];
            BOOL lastAndComplete = i == (ws.count - 1) && !sp.lastUnknownSearchWordComplete;
            BOOL decryptAbbreviations = [self needDecryptAbbreviations];
            if (wd.length > 0 && (!conjunction || lastAndComplete))
            {
                if (first)
                {
                    sp.firstUnknownSearchWord = decryptAbbreviations ? [OAAbbreviations replace:wd] : wd;
                    first = false;
                }
                else
                {
                    [sp.otherUnknownWords addObject: decryptAbbreviations? [OAAbbreviations replace:wd] : wd];
                }
            }
        }
    }
    return sp;
}

- (BOOL) needDecryptAbbreviations
{
    NSString *langs = _settings ? [_settings getRegionLang] : nil;
    if (langs)
    {
        NSArray<NSString *> *langArr = [langs componentsSeparatedByString:@","];
        for (NSString *lang in langArr)
        {
            if ([lang isEqualToString:@"en"])
                return YES;
        }
    }
    return NO;
}

- (instancetype) initWithSettings:(OASearchSettings *)settings
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _resourceLocations = [NSMapTable strongToStrongObjectsMapTable];
        
        self.settings = settings;

        self.words = [NSMutableArray array];
        _fullTextSearchPhrase = @"";
        _unknownSearchPhrase = @"";
        _words = [NSMutableArray new];
        _firstUnknownSearchWord = @"";
        _otherUnknownWords = [NSMutableArray new];
        _mainUnknownWordToSearch = nil;
        _unknownWordsMatcher = [NSMutableArray new];
    }
    return self;
}

- (OASearchPhrase *) generateNewPhrase:(NSString *)text settings:(OASearchSettings *)settings
{
    NSString *textToSearch = [self normalizeSearchText:text];
    NSMutableArray<OASearchWord *> *leftWords = [NSMutableArray arrayWithArray:_words];
    NSString *thisTxt = [self getText:YES];
    NSMutableArray<OASearchWord *> *foundWords = [NSMutableArray new];
    thisTxt = [self normalizeSearchText:thisTxt];
    if ([textToSearch hasPrefix:thisTxt])
    {
        // string is longer
        textToSearch = [textToSearch substringFromIndex:[self getText:NO].length];
        [foundWords addObjectsFromArray:_words];
        [leftWords removeAllObjects];
    }
    for (OASearchWord *w in leftWords)
    {
        if ([textToSearch hasPrefix:[w.word stringByAppendingString:DELIMITER]])
        {
            [foundWords addObject:w];
            textToSearch = [textToSearch substringFromIndex:w.word.length + DELIMITER.length];
        }
        else
        {
            break;
        }
    }
    return [self createNewSearchPhrase:settings fullText:text foundWords:foundWords textToSearch:textToSearch];
}

- (NSString *) normalizeSearchText:(NSString *)s
{
    BOOL norm = NO;
    for (NSInteger i = 0; i < s.length && !norm; i++)
    {
        unichar uc = (unichar)[s characterAtIndex:i];
        NSString *ch = [NSString stringWithCharacters:&uc length:1];
        for (NSInteger j = 0; j < CHARS_TO_NORMALIZE_KEY.count; j++) {
            if ([ch isEqualToString:CHARS_TO_NORMALIZE_KEY[j]]) {
                norm = true;
                break;
            }
        }
    }
    if (!norm)
        return s;

    for (NSInteger k = 0; k < CHARS_TO_NORMALIZE_KEY.count; k++)
    {
        s = [s stringByReplacingOccurrencesOfString:CHARS_TO_NORMALIZE_KEY[k] withString:CHARS_TO_NORMALIZE_VALUE[k]];
    }
    return s;
}

- (int) countWords:(NSString *)word
{
    NSArray<NSString *> *ws = [word componentsSeparatedByRegex:ALLDELIMITERS];
    int cnt = 0;
    for (int i = 0; i < ws.count; i++)
    {
        NSString *wd = ws[i].trim;
        if (wd.length > 0)
        {
            cnt++;
        }
    }
    return cnt;
}

+ (NSMutableArray<NSString *> *) splitWords:(NSString *)w ws:(NSMutableArray<NSString *> *)ws delimiters:(NSString *)delimiters
{
    if (w && w.length > 0)
    {
        NSArray<NSString *> *wrs = [w componentsSeparatedByRegex:delimiters];
        for (int i = 0; i < [wrs count]; i++)
        {
            NSString *wd = wrs[i].trim;
            if (wd.length > 0)
                [ws addObject:wd];
        }
    }
    return ws;
}

- (OASearchPhrase *) selectWord:(OASearchResult *) res unknownWords:(NSArray<NSString *> *)unknownWords lastComplete:(BOOL)lastComplete
{
    OASearchPhrase *sp = [[OASearchPhrase alloc] initWithSettings:_settings];
    [self addResult:res sp:sp];
    OASearchResult *prnt = res.parentSearchResult;
    while (prnt != nil)
    {
        [self addResult:prnt sp:sp];
        prnt = prnt.parentSearchResult;
    }
    [sp.words insertObjects:_words atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _words.count)]];
    if (unknownWords != nil)
    {
        sp.lastUnknownSearchWordComplete = lastComplete;
        NSMutableString *genUnknownSearchPhrase = [NSMutableString new];
        for (NSInteger i = 0; i < unknownWords.count; i++)
        {
            if (i == 0)
                sp.firstUnknownSearchWord = unknownWords[0];
            else
                [sp.otherUnknownWords addObject:unknownWords[i]];
            
            [genUnknownSearchPhrase appendString:unknownWords[i]];
            [genUnknownSearchPhrase appendString:@" "];
        }
        sp.fullTextSearchPhrase = _fullTextSearchPhrase;
        sp.unknownSearchPhrase = genUnknownSearchPhrase.trim;
    }
    return sp;
}

- (void) calcMainUnknownWordToSearch
{
    if (_mainUnknownWordToSearch != nil)
        return;
    
    NSMutableArray<NSString *> *unknownSearchWords = _otherUnknownWords;
    _mainUnknownWordToSearch = _firstUnknownSearchWord;
    _mainUnknownSearchWordComplete = _lastUnknownSearchWordComplete;
    if (unknownSearchWords && unknownSearchWords.count > 0)
    {
        _mainUnknownSearchWordComplete = YES;
        NSMutableArray<NSString *> *searchWords = [NSMutableArray arrayWithArray:unknownSearchWords];
        [searchWords insertObject:_firstUnknownSearchWord atIndex:0];
        [searchWords sortUsingComparator:self.commonWordsComparator];
        for (NSString *s in searchWords)
        {
            if (s.length > 0)
            {
                _mainUnknownWordToSearch = s.trim;
                if ([_mainUnknownWordToSearch hasSuffix:@"."])
                {
                    _mainUnknownWordToSearch = [_mainUnknownWordToSearch substringToIndex:_mainUnknownWordToSearch.length - 1];
                    _mainUnknownSearchWordComplete = NO;
                }
                NSUInteger unknownInd = [unknownSearchWords indexOfObject:s];
                if (!_lastUnknownSearchWordComplete && unknownSearchWords.count - 1 == unknownInd)
                {
                    _mainUnknownSearchWordComplete = NO;
                }
                break;
            }
        }
        if ([OAArabicNormalizer isSpecialArabic:_mainUnknownWordToSearch]) {
            _mainUnknownWordToSearch = [OAArabicNormalizer normalize:_mainUnknownWordToSearch] ?: _mainUnknownWordToSearch;
        }
    }
}

- (BOOL) isMainUnknownSearchWordComplete
{
    return _mainUnknownSearchWordComplete;
}

- (BOOL) hasMoreThanOneUnknownSearchWord
{
    return _otherUnknownWords.count > 0;
}

- (NSMutableArray<NSString *> *) getUnknownSearchWords
{
    return _otherUnknownWords;
}

- (NSMutableArray<OASearchWord *> *) getWords
{
    return self.words;
}

- (BOOL) isFirstUnknownSearchWordComplete
{
    return [self hasMoreThanOneUnknownSearchWord] || [self isLastUnknownSearchWordComplete];
}

- (BOOL) isLastUnknownSearchWordComplete
{
    return self.lastUnknownSearchWordComplete;
}

- (NSString *) getFullSearchPhrase
{
    return _fullTextSearchPhrase;
}

- (NSString *) getUnknownSearchPhrase
{
    return _unknownSearchPhrase;
}

- (NSString *) getFirstUnknownSearchWord
{
    return _firstUnknownSearchWord;
}

- (OAPOIBaseType *) getUnselectedPoiType
{
    return _unselectedPoiType;
}

- (void) setUnselectedPoiType:(OAPOIBaseType *)unselectedPoiType
{
    _unselectedPoiType = unselectedPoiType;
}

- (OANameStringMatcher *) getFullUnknownNameMatcher
{
    // TODO investigate diesel 95
    if ([self isLastUnknownSearchWordComplete] || [self hasMoreThanOneUnknownSearchWord])
        return [[OANameStringMatcher alloc] initWithNamePart:_unknownSearchPhrase mode:TRIM_AND_CHECK_ONLY_STARTS_WITH];
    else
        return [[OANameStringMatcher alloc] initWithNamePart:_unknownSearchPhrase mode:CHECK_STARTS_FROM_SPACE];
}

- (BOOL) isUnknownSearchWordPresent
{
    return _firstUnknownSearchWord.length > 0;
}

- (QuadRect *) getRadiusBBox31ToSearch:(int)radius
{
    QuadRect *searchBBox31 = self.settings.getSearchBBox31;
    if (searchBBox31)
        return searchBBox31;

    int radiusInMeters = [self getRadiusSearch:radius];
    QuadRect *cache1kmRect = [self get1km31Rect];
    if (!cache1kmRect)
        return nil;

    long max = ((long)1 << 31) - 1;
    double dx = (cache1kmRect.width / 2) * radiusInMeters / 1000;
    double dy = (cache1kmRect.height / 2) * radiusInMeters / 1000;
    double topLeftX = MAX(0, cache1kmRect.left - dx);
    double topLeftY = MAX(0, cache1kmRect.top - dy);
    double bottomRightX = MIN(max, cache1kmRect.right + dx);
    double bottomRightY = MIN(max, cache1kmRect.bottom + dy);
    return [[QuadRect alloc] initWithLeft:topLeftX top:topLeftY right:bottomRightX bottom:bottomRightY];
}

- (QuadRect *) get1km31Rect
{
    if (self.cache1kmRect)
        return self.cache1kmRect;
    
    CLLocation *l = [self getLastTokenLocation];
    if (!l)
        return nil;
    
    self.cache1kmRect = [OASearchPhrase calculateBbox:@(1000) location:l];
    return self.cache1kmRect;
}

+ (QuadRect *) calculateBbox:(NSNumber *)radiusMeters location:(CLLocation *)location
{
    OsmAnd::LatLon center(location.coordinate.latitude, location.coordinate.longitude);
    OsmAnd::LatLon nw = OsmAnd::Utilities::rhumbDestinationPoint(center, [radiusMeters doubleValue], 315.0);
    OsmAnd::LatLon se = OsmAnd::Utilities::rhumbDestinationPoint(center, [radiusMeters doubleValue], 135.0);
    int left = OsmAnd::Utilities::get31TileNumberX(nw.longitude);
    int top = OsmAnd::Utilities::get31TileNumberY(nw.latitude);
    int right = OsmAnd::Utilities::get31TileNumberX(se.longitude);
    int bottom = OsmAnd::Utilities::get31TileNumberY(se.latitude);
    return [[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
}

- (NSArray<NSString *> *) getRadiusOfflineIndexes:(int)meters dt:(EOASearchPhraseDataType)dt
{
    QuadRect *rect = meters > 0 ? [self getRadiusBBox31ToSearch:meters] : nil;
    return [self getOfflineIndexes:rect dt:dt];
    
}

- (BOOL) containsData:(NSString *)localResourceId rect:(QuadRect *)rect desiredDataTypes:(OsmAnd::ObfDataTypesMask)desiredDataTypes
{
    return [self containsData:localResourceId rect:rect desiredDataTypes:desiredDataTypes zoomLevel:OsmAnd::InvalidZoomLevel];
}

- (BOOL) containsData:(NSString *)localResourceId rect:(QuadRect *)rect desiredDataTypes:(OsmAnd::ObfDataTypesMask)desiredDataTypes zoomLevel:(OsmAnd::ZoomLevel)zoomLevel
{
    const auto& localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(localResourceId));
    if (localResource)
    {
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
        if (obfMetadata)
        {
            OsmAnd::AreaI pBbox31 = OsmAnd::AreaI((int)rect.top, (int)rect.left, (int)rect.bottom, (int)rect.right);
            if (zoomLevel == OsmAnd::InvalidZoomLevel)
                return obfMetadata->obfFile->obfInfo->containsDataFor(&pBbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, desiredDataTypes);
            else
                return obfMetadata->obfFile->obfInfo->containsDataFor(&pBbox31, zoomLevel, zoomLevel, desiredDataTypes);
        }
    }
    return NO;
}

- (NSArray<NSString *> *) getOfflineIndexes:(QuadRect *)rect dt:(EOASearchPhraseDataType)dt
{
    NSArray<NSString *> *indexes = _indexes ? _indexes : [self.settings getOfflineIndexes];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    if (rect)
    {
        for (NSString *resId in indexes)
        {
            if (dt == P_DATA_TYPE_POI)
            {
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI)])
                    [result addObject:resId];
            }
            else if (dt == P_DATA_TYPE_ADDRESS)
            {
                // containsAddressData not all maps supported
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::POI)])
                    [result addObject:resId];
            }
            else if (dt == P_DATA_TYPE_ROUTING)
            {
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Routing) zoomLevel:OsmAnd::ZoomLevel15])
                    [result addObject:resId];
            }
            else
            {
                if ([self containsData:resId rect:rect desiredDataTypes:OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Map) zoomLevel:OsmAnd::ZoomLevel15])
                    [result addObject:resId];
            }
        }
    }
    return result;
}

- (NSArray<NSString *> *) getOfflineIndexes
{
    if (_indexes)
        return _indexes;
    
    return [self.settings getOfflineIndexes];
}

- (OASearchSettings *) getSettings
{
    return self.settings;
}

- (NSString *) getDelimiter
{
    return DELIMITER;
}


- (int) getRadiusLevel
{
    return [self.settings getRadiusLevel];
}

- (NSArray<OAObjectType *> *) getSearchTypes
{
    return !self.settings ? nil : [self.settings getSearchTypes];
}

- (BOOL) isCustomSearch
{
    return [self getSearchTypes] != nil;
}

- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType
{
    return [self isSearchTypeAllowed:searchType exclusive:NO];
}

- (BOOL) isSearchTypeAllowed:(EOAObjectType)searchType exclusive:(BOOL)exclusive
{
    NSArray<OAObjectType *> *searchTypes = [self getSearchTypes];
    if (!searchTypes)
    {
        return !exclusive;
    }
    else
    {
        if (exclusive && searchTypes.count > 1)
            return NO;
        
        for (OAObjectType *type in searchTypes)
            if (type.type == searchType)
                return YES;

        return NO;
    }
}

- (BOOL) isEmptyQueryAllowed
{
    return [self.settings isEmptyQueryAllowed];
}

- (BOOL) isSortByName
{
    return [self.settings isSortByName];
}

- (BOOL) isInAddressSearch
{
    return [self.settings isInAddressSearch];
}

- (OASearchPhrase *) selectWord:(OASearchResult *)res
{
    return [self selectWord:res unknownWords:nil lastComplete:NO];
}

- (void) addResult:(OASearchResult *)res sp:(OASearchPhrase *)sp
{
    OASearchWord *sw = [[OASearchWord alloc] initWithWord:res.wordsSpan ? res.wordsSpan : [res.localeName trim] res:res];
    [sp.words insertObject:sw atIndex:0];
}

- (BOOL) isLastWord:(EOAObjectType)p
{
    for (NSInteger i = (NSInteger) self.words.count - 1; i >= 0; i--)
    {
        OASearchWord *sw = self.words[i];
        if ([sw getType] == p)
            return YES;

        if ([sw getType] != EOAObjectTypeUnknownNameFilter)
            return NO;
    }
    return NO;
}

- (OAObjectType *) getExclusiveSearchType
{
    OASearchWord *lastWord = [self getLastSelectedWord];
    if (lastWord)
    {
        return [OAObjectType getExclusiveSearchType:[lastWord getType]];
    }
    return nil;
}

- (OANameStringMatcher *) getMainUnknownNameStringMatcher
{
    [self calcMainUnknownWordToSearch];
    if (_mainUnknownNameStringMatcher == nil)
        _mainUnknownNameStringMatcher = [self getNameStringMatcher:_mainUnknownWordToSearch complete:_mainUnknownSearchWordComplete];
    
    return _mainUnknownNameStringMatcher;
}

- (OANameStringMatcher *) getFirstUnknownNameStringMatcher
{
    if (_firstUnknownNameStringMatcher == nil)
        _firstUnknownNameStringMatcher = [self getNameStringMatcher:_firstUnknownSearchWord complete:[self isFirstUnknownSearchWordComplete]];
    
    return _firstUnknownNameStringMatcher;
}

- (OANameStringMatcher *) getUnknownNameStringMatcher:(NSInteger)i
{
    while (_unknownWordsMatcher.count <= i)
    {
        NSUInteger ind = _unknownWordsMatcher.count;
        BOOL completeMatch = ind < _otherUnknownWords.count - 1 || [self isLastUnknownSearchWordComplete];
        [_unknownWordsMatcher addObject:[self getNameStringMatcher:_otherUnknownWords[ind] complete:completeMatch]];
    }
    return _unknownWordsMatcher[i];
}

- (OANameStringMatcher *) getFullNameStringMatcher
{
    return [self getNameStringMatcher:_fullTextSearchPhrase complete:NO];
}

- (OANameStringMatcher *) getNameStringMatcher:(NSString *)word complete:(BOOL)complete
{
    return [[OANameStringMatcher alloc] initWithNamePart:word mode:complete ?
                                CHECK_EQUALS_FROM_SPACE :
                                CHECK_STARTS_FROM_SPACE];
    
}

- (BOOL) hasObjectType:(EOAObjectType)p
{
    for (OASearchWord *s in self.words)
    {
        if([s getType] == p)
            return YES;
    }
    return NO;
}

- (void) syncWordsWithResults
{
    for (OASearchWord *w in self.words)
        [w syncWordWithResult];
}

- (NSString *)getText:(BOOL)includeUnknownPart
{
    NSMutableString *sb = [NSMutableString string];
    for (OASearchWord *s in self.words)
    {
        if (s.word != nil)
            [sb appendString:s.word];
        else
            NSLog(@"[OASearchPhrase] Warning: OASearchWord.word is nil for a word in words");
        
        [sb appendString:DELIMITER];
    }
    
    if (includeUnknownPart)
    {
        if (_unknownSearchPhrase != nil)
            [sb appendString:_unknownSearchPhrase];
        else
            NSLog(@"[OASearchPhrase] Warning: _unknownSearchPhrase is nil");
    }
    
    return [NSString stringWithString:sb];
}

- (NSString *) getTextWithoutLastWord
{
    NSMutableString *sb = [NSMutableString string];
    NSMutableArray<OASearchWord *> *words = [NSMutableArray arrayWithArray:self.words];
    if (_unknownSearchPhrase.trim.length == 0 && words.count > 0)
        [words removeObjectAtIndex:words.count - 1];

    for (OASearchWord *s in words)
    {
        [sb appendString:s.word];
        [sb appendString:DELIMITER];
    }

    return [NSString stringWithString:sb];
}

- (NSString *) getStringRerpresentation
{
    NSMutableString *sb = [NSMutableString string];
    for (OASearchWord *s in self.words)
    {
        [sb appendString:s.word];
        [sb appendFormat:@" [%@], ", [OAObjectType toString:[s getType]]];
    }
    [sb appendString:self.unknownSearchPhrase];
    return [NSString stringWithString:sb];
}

- (NSString *) toString
{
    return [self getStringRerpresentation];
}

- (BOOL) isNoSelectedType
{
    return self.words.count == 0;
}

- (BOOL) isEmpty
{
    return self.words.count == 0 && self.unknownSearchPhrase.length == 0;
}


- (OASearchWord *) getLastSelectedWord
{
    if (self.words.count == 0)
        return nil;
    
    return self.words[self.words.count - 1];
}


- (CLLocation *) getWordLocation
{
    for (NSInteger i = (NSInteger) self.words.count - 1; i >= 0; i--)
    {
        OASearchWord *sw = self.words[i];
        if ([sw getLocation])
            return [sw getLocation];
    }
    return nil;
}

- (CLLocation *) getLastTokenLocation
{
    for (NSInteger i = (NSInteger) self.words.count - 1; i >= 0; i--)
    {
        OASearchWord *sw = self.words[i];
        if ([sw getLocation])
            return [sw getLocation];
    }
    // last token or myLocationOrVisibleMap if not selected
    return self.settings ? [self.settings getOriginalLocation] : nil;
}

- (void) selectFile:(NSString *)resourceId
{
    if (!_indexes)
        _indexes = [NSMutableArray array];
    
    if (![_indexes containsObject:resourceId])
        [_indexes addObject:resourceId];
}

- (CLLocation *) getLocation:(NSString *)resourceId
{
    NSObject *obj = [_resourceLocations objectForKey:resourceId];
    if (obj)
    {
        if ([obj isKindOfClass:[CLLocation class]])
            return (CLLocation *)obj;
        else
            return nil;
    }
    
    CLLocation *location;
    const auto& localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    if (localResource)
    {
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
        if (obfMetadata)
        {
            if (!obfMetadata->obfFile->obfInfo->mapSections.empty())
            {
                const auto rc1 = obfMetadata->obfFile->obfInfo->mapSections.first()->getCenterLatLon().getValuePtrOrNullptr();
                if (rc1 != nullptr)
                    location = [[CLLocation alloc] initWithLatitude:rc1->latitude longitude:rc1->longitude];
            }
            else
            {
                const auto rc1 = obfMetadata->obfFile->obfInfo->getRegionCenter().getValuePtrOrNullptr();
                if (rc1 != nullptr)
                    location = [[CLLocation alloc] initWithLatitude:rc1->latitude longitude:rc1->longitude];
            }
        }
    }

    [_resourceLocations setObject:(location ? location : [NSNull null]) forKey:resourceId];
    return location;
}

- (void) sortFiles
{
    if (!_indexes)
        _indexes = [NSMutableArray arrayWithArray:[self getOfflineIndexes]];
    
    CLLocation *ll = [self getLastTokenLocation];
    if (ll)
    {
        [_indexes sortUsingComparator:^NSComparisonResult(NSString * _Nonnull id1, NSString * _Nonnull id2) {
            NSString *first = [[id1 stringByReplacingOccurrencesOfString:@".live.obf" withString:@""] stringByReplacingOccurrencesOfString:@".obf" withString:@""];
            NSString *second = [[id2 stringByReplacingOccurrencesOfString:@".live.obf" withString:@""] stringByReplacingOccurrencesOfString:@".obf" withString:@""];
            NSRange rangeFirst = [first rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
            NSRange rangeSecond = [second rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
            if (rangeFirst.location != NSNotFound && rangeSecond.location == NSNotFound)
            {
                NSString *base = [first substringToIndex:rangeFirst.location - 1];
                if ([base isEqualToString:second])
                    return NSOrderedAscending;
            }
            else if (rangeFirst.location == NSNotFound && rangeSecond.location != NSNotFound)
            {
                NSString *base = [second substringToIndex:rangeSecond.location - 1];
                if ([base isEqualToString:first])
                    return NSOrderedDescending;
            }
            else if (rangeFirst.location != NSNotFound && rangeSecond.location != NSNotFound)
            {
                return [first compare:second];
            }
            
            CLLocation *rc1 = [self getLocation:id1];
            CLLocation *rc2 = [self getLocation:id2];
            double d1 = !rc1 ? 10000000.0 : [rc1 distanceFromLocation:ll];
            double d2 = !rc2 ? 10000000.0 : [rc2 distanceFromLocation:ll];
            return [[NSNumber numberWithDouble:d1] compare:[NSNumber numberWithDouble:d2]];
            
        }];
    }
}

- (NSInteger) countUnknownWordsMatchMainResult:(OASearchResult *)sr
{
    return [self countUnknownWordsMatch:sr localeName:sr.localeName otherNames:sr.otherNames matchingWordsCount:0];
}

- (NSInteger) countUnknownWordsMatchMainResult:(OASearchResult *)sr matchingWordsCount:(NSInteger)matchingWordsCount
{
    return [self countUnknownWordsMatch:sr localeName:sr.localeName otherNames:sr.otherNames matchingWordsCount:matchingWordsCount];
}

- (NSInteger) countUnknownWordsMatch:(OASearchResult *)sr localeName:(NSString *)localeName otherNames:(NSMutableArray<NSString *> *)otherNames matchingWordsCount:(NSInteger)matchingWordsCount
{
    NSInteger r = 0;
    if (_otherUnknownWords.count > 0)
    {
        for (NSInteger i = 0; i < _otherUnknownWords.count; i++)
        {
            BOOL match = NO;
            if (i < matchingWordsCount - 1)
            {
                match = YES;
            }
            else
            {
                OANameStringMatcher *ms = [self getUnknownNameStringMatcher:i];
                if ([ms matches:localeName] || [ms matchesMap:otherNames] || [ms matches:sr.alternateName])
                {
                    match = YES;
                }
            }
            if (match)
            {
                if (sr.otherWordsMatch == nil)
                    sr.otherWordsMatch = [NSMutableSet new];
                [sr.otherWordsMatch addObject:_otherUnknownWords[i]];
                r++;
            }
        }
    }
    if (matchingWordsCount > 0)
    {
        sr.firstUnknownWordMatches = YES;
        r++;
    }
    else
    {
        BOOL match = [localeName isEqualToString:_firstUnknownSearchWord]
            || [[self getFirstUnknownNameStringMatcher] matches:localeName]
            || [[self getFirstUnknownNameStringMatcher] matchesMap:otherNames]
            || [[self getFirstUnknownNameStringMatcher] matches:sr.alternateName];
        if (match)
            r++;
        sr.firstUnknownWordMatches = match || sr.firstUnknownWordMatches;
    }
    return r;
}

- (NSString *) getLastUnknownSearchWord
{
    if (_otherUnknownWords.count > 0)
        return _otherUnknownWords[_otherUnknownWords.count - 1];
    return _firstUnknownSearchWord;
}

- (int) getRadiusSearch:(int)meters radiusLevel:(int)radiusLevel
{
    int res = meters;
    for (int k = 0; k < radiusLevel; k++)
    {
        res = res * (k % 2 == 0 ? 2 : 3);
    }
    return res;
}

- (int) getRadiusSearch:(int)meters
{
    return [self getRadiusSearch:meters radiusLevel:self.getRadiusLevel - 1];
}

- (int) getNextRadiusSearch:(int) meters
{
    return [self getRadiusSearch:meters radiusLevel:self.getRadiusLevel];
}

+ (NSComparisonResult) icompare:(int)x y:(int)y
{
    return (x < y) ? NSOrderedAscending : ((x == y) ? NSOrderedSame : NSOrderedDescending);
}

+ (int) lengthWithoutNumbers:(NSString *)s
{
    int len = 0;
    for (int k = 0; k < s.length; k++)
    {
        if ([s characterAtIndex:k] >= '0' && [s characterAtIndex:k] <= '9')
        {
        }
        else
        {
            len++;
        }
    }
    return len;
}

- (int) getUnknownWordToSearchBuildingInd
{
    if (_otherUnknownWords.count > 0 && [OAUtilities extractFirstIntegerNumber:[self getFirstUnknownSearchWord]] == 0)
    {
        int ind = 0;
        for (NSString *wrd in _otherUnknownWords)
        {
            ind++;
            if ([OAUtilities extractFirstIntegerNumber:wrd] != 0)
                return ind;
        }
    }
    return 0;
}

- (OANameStringMatcher *) getUnknownWordToSearchBuildingNameMatcher
{
    int ind = [self getUnknownWordToSearchBuildingInd];
    if(ind > 0) {
        return [self getUnknownNameStringMatcher:ind - 1];
    } else {
        return [self getFirstUnknownNameStringMatcher];
    }
}

- (NSString *) getUnknownWordToSearchBuilding
{
    int ind = [self getUnknownWordToSearchBuildingInd];
    if(ind > 0) {
        return _otherUnknownWords[ind - 1];
    } else {
        return _firstUnknownSearchWord;
    }
}

- (NSString *) getUnknownWordToSearch
{
    [self calcMainUnknownWordToSearch];
    return _mainUnknownWordToSearch;
}

- (BOOL) isTextComplete:(NSString *)fullText
{
    BOOL lastUnknownSearchWordComplete = NO;
    if (fullText.length > 0)
    {
        unichar ch = [fullText characterAtIndex:(fullText.length - 1)];
        lastUnknownSearchWordComplete = ch == ' ' || ch == ',' || ch == '\r' || ch == '\n'
                || ch == ';';
    }
    return lastUnknownSearchWordComplete;
}

+ (NSString *) stripBraces:(NSString *)localeName
{
    if (localeName == nil)
    {
        return nil;
    }
    NSInteger i = [localeName rangeOfString:@"("].location;
        NSString *retName = localeName;
        
        if (i != NSNotFound) {
            retName = [localeName substringToIndex:i];
            NSInteger j = [localeName rangeOfString:@")" options:0 range:NSMakeRange(i, localeName.length - i)].location;
            
            if (j != NSNotFound) {
                NSString *firstPart = [retName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *remainingPart = [localeName substringFromIndex:j + 1];
                retName = [[NSString stringWithFormat:@"%@ %@", firstPart, remainingPart] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
        }
        return retName;
}

+ (NSMutableArray<NSString *> *) stripBracesArray:(NSMutableArray<NSString *> *)names
{
    NSMutableArray<NSString *> *lst = [NSMutableArray arrayWithCapacity:names.count];
    for (NSString *s in names)
    {
        NSString *strippedString = [self stripBraces:s];
        [lst addObject:strippedString];
    }
    return lst;
}

+ (NSString *) ALLDELIMITERS
{
    return ALLDELIMITERS;
}

- (NSString *) selectMainUnknownWordToSearch:(NSMutableArray<NSString *> *)searchWords
{
    [searchWords sortUsingComparator:self.commonWordsComparator];
    
    for (NSString *s in searchWords)
    {
        NSString *trimmedString = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimmedString length] > 0)
        {
            return trimmedString;
        }
    }
    return @"";
}

@end
