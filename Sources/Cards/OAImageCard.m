//
//  OAMapillaryImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAImageCard.h"
#import "OAImageCardCell.h"

@implementation OAImageCard
{
    BOOL _downloading;
    BOOL _downloaded;
}

- (id) initWithData:(NSDictionary *)data
{
    self = [super init];
    if (self) {
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

- (void) build:(UICollectionViewCell *) cell
{
    [super build:cell];
    
    OAImageCardCell *imageCell;
    if (cell && [cell isKindOfClass:OAImageCardCell.class])
        imageCell = (OAImageCardCell *) cell;
    
    if (imageCell)
    {
        imageCell.loadingIndicatorView.hidesWhenStopped = YES;
        if (self.image)
        {
            imageCell.imageView.hidden = NO;
            [imageCell.imageView setImage:self.image];
            [imageCell.urlTextView setHidden:YES];
            imageCell.loadingIndicatorView.hidden = YES;
            [imageCell.loadingIndicatorView stopAnimating];
        }
        else
        {
            [imageCell.imageView setImage:nil];
            if (!_downloaded)
            {
                [imageCell.loadingIndicatorView startAnimating];
                imageCell.loadingIndicatorView.hidden = NO;
                [self downloadImage];
            }
            else
            {
                imageCell.imageView.hidden = YES;
                [imageCell.urlTextView setHidden:NO];
                [imageCell.urlTextView setText:self.imageUrl];
                imageCell.loadingIndicatorView.hidden = YES;
                [imageCell.loadingIndicatorView stopAnimating];
            }
        }
        [imageCell setUserName:self.userName];
        
        if (self.topIcon && self.topIcon.length > 0)
            [imageCell.logoView setImage:[UIImage imageNamed:self.topIcon]];
        else
            [imageCell.logoView setImage:nil];
    }
}

+ (NSString *) getCellNibId
{
    return [OAImageCardCell getCellIdentifier];
}

@end
