//
//  OAMapillaryImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <CocoaSecurity.h>
#import "OAImageCard.h"
#import "OAImageCardCell.h"
#import "OACollapsableCardsView.h"
#import "OAMapillaryImageCard.h"
#import "OAMapillaryContributeCard.h"
#import "OAUrlImageCard.h"
#import "OAWikiImageCard.h"

@interface OAImageCard ()

@property (nonatomic) OAImageCardCell *collectionCell;

@end

@implementation OAImageCard
{
    BOOL _downloading;
    BOOL _downloaded;
}

- (id) initWithData:(NSDictionary *)data
{
    self = [super init];
    if (self)
    {
        _type = data[@"type"];
        _ca = [data[@"ca"] doubleValue];
        _latitude = [data[@"lat"] doubleValue];
        _longitude = [data[@"lon"] doubleValue];
        _timestamp = data[@"timestamp"];
        _key = data[@"key"];
        _title = data[@"title"];
        _userName = data[@"username"];
        _url = data[@"url"];
        _imageUrl = data[@"imageUrl"];
        _imageHiresUrl = data[@"imageHiresUrl"];
        _externalLink = [data[@"externalLink"] boolValue];
        _topIcon = [self getIconName:data[@"topIcon"]];
        _downloaded = NO;
        _downloading = NO;
    }
    return self;
}

- (NSString *) getIconName:(NSString *)serverIconName
{
    if (serverIconName && [serverIconName isEqualToString:@"ic_logo_mapillary"])
        return @"ic_custom_mapillary_color_logo.png";
    else if ([_type isEqualToString:@"wikimedia-photo"])
        return @"ic_custom_logo_wikimedia.png";
    else if ([_type isEqualToString:@"wikidata-photo"])
        return @"ic_custom_logo_wikidata.png";
    else
        return serverIconName;
}

- (void) downloadImage
{
    if (!_imageUrl || _imageUrl.length == 0)
        return;
    _downloading = YES;
    NSURL *imgURL = [NSURL URLWithString:_imageUrl];
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:imgURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            if (data)
                _image = [[UIImage alloc] initWithData:data];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate)
                [self.delegate requestCardReload:self];
        });
        _downloaded = YES;
        _downloading = NO;
    }] resume];
}

- (NSString *) getSuitableUrl
{
    return (_imageHiresUrl && _imageHiresUrl.length > 0) ? _imageHiresUrl : _imageUrl;
}

- (void)build:(UICollectionViewCell *) cell
{
    if (cell && [cell isKindOfClass:OAImageCardCell.class])
        _collectionCell = (OAImageCardCell *) cell;
    [super build:cell];
}

- (void)update
{
    if (_collectionCell)
    {
        _collectionCell.loadingIndicatorView.hidesWhenStopped = YES;
        if (self.image)
        {
            _collectionCell.imageView.hidden = NO;
            [_collectionCell.imageView setImage:self.image];
            [_collectionCell.urlTextView setHidden:YES];
            _collectionCell.loadingIndicatorView.hidden = YES;
            [_collectionCell.loadingIndicatorView stopAnimating];
        }
        else
        {
            [_collectionCell.imageView setImage:nil];
            if (!_downloaded)
            {
                [_collectionCell.loadingIndicatorView startAnimating];
                _collectionCell.loadingIndicatorView.hidden = NO;
                [self downloadImage];
            }
            else
            {
                _collectionCell.imageView.hidden = YES;
                [_collectionCell.urlTextView setHidden:NO];
                [_collectionCell.urlTextView setText:self.imageUrl];
                _collectionCell.loadingIndicatorView.hidden = YES;
                [_collectionCell.loadingIndicatorView stopAnimating];
            }
        }
        [_collectionCell setUserName:self.userName];

        if (self.topIcon && self.topIcon.length > 0)
            [_collectionCell.logoView setImage:[UIImage imageNamed:self.topIcon]];
        else
            [_collectionCell.logoView setImage:nil];
    }
}

+ (NSString *) getCellNibId
{
    return [OAImageCardCell getCellIdentifier];
}

@end
