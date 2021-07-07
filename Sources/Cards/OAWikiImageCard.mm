//
//  OAWikiImageCard.mm
//  OsmAnd
//
//  Created by Skalii on 05.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAWikiImageCard.h"
#import "OAWikiWebViewController.h"
#import "OAMapPanelViewController.h"
#import "OAWebViewController.h"

@implementation OAWikiImage
{
    NSString *_wikiMediaTag;
}

- (instancetype)initWithWikiMediaTag:(NSString *)wikiMediaTag imageName:(NSString *)imageName imageStubUrl:(NSString *)imageStubUrl imageHiResUrl:(NSString *)imageHiResUrl
{
    self = [super init];
    if (self)
    {
        _wikiMediaTag = wikiMediaTag;
        _imageName = imageName;
        _imageStubUrl = imageStubUrl;
        _imageHiResUrl = imageHiResUrl;
    }
    return self;
}

- (NSString *)getUrlWithCommonAttributions
{
    NSString *url = [NSString stringWithFormat:@"%@%@%@", WIKIMEDIA_COMMONS_URL, WIKIMEDIA_FILE, _wikiMediaTag];
    return url;
}

@end

@interface OAWikiImageCard ()

@property (nonatomic) NSString *type;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *imageUrl;
@property (nonatomic) NSString *topIcon;

@end

@implementation OAWikiImageCard
{
    NSString *_urlWithCommonAttributions;
}

@dynamic type, title, url, imageUrl, topIcon;

- (instancetype)initWithWikiImage:(OAWikiImage *)wikiImage type:(NSString *)type
{
    self = [super init];
    if (self)
    {
        self.type = type;
        _urlWithCommonAttributions = [wikiImage getUrlWithCommonAttributions];
        if (self.topIcon.length == 0)
            self.topIcon = @"ic_custom_logo_wikimedia.png";
        [self setImageUrl:@""];
        self.imageUrl = wikiImage.imageStubUrl;
        self.title = wikiImage.imageName;
        self.url = self.imageUrl;
    }
    return self;
}

- (void)onCardPressed:(OAMapPanelViewController *) mapPanel
{
    OAWebViewController *viewController = [[OAWebViewController alloc] initWithUrlAndTitle:_urlWithCommonAttributions title:self.title];
    [mapPanel.navigationController pushViewController:viewController animated:YES];
}

@end
