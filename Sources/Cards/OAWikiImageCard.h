//
//  OAWikiImageCard.h
//  OsmAnd
//
//  Created by Skalii on 05.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAImageCard.h"

#define WIKIMEDIA_COMMONS_URL @"https://commons.wikimedia.org/wiki/"
#define WIKIMEDIA_FILE @"File:"

@class OAWikiImage;

@interface OAWikiImage : NSObject

@property (nonatomic, readonly) NSString *imageName;
@property (nonatomic, readonly) NSString *imageStubUrl;
@property (nonatomic, readonly) NSString *imageHiResUrl;

- (instancetype)initWithWikiMediaTag:(NSString *)wikiMediaTag imageName:(NSString *)imageName imageStubUrl:(NSString *)imageStubUrl imageHiResUrl:(NSString *)imageHiResUrl;

- (NSString *)getUrlWithCommonAttributions;

@end

@interface OAWikiImageCard : OAImageCard

- (instancetype)initWithWikiImage:(OAWikiImage *)wikiImage type:(NSString *)type;

@end
