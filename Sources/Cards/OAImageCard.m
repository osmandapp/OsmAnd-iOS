//
//  OAMapillaryImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/24/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAImageCard.h"
#import "OAImageCardCell.h"

#define kUserLabelInset 8

#define kImageCardId @"OAImageCardCell"

@implementation OAImageCard

- (id) initWithData:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        _type = data[@"type"];
        _ca = ((NSNumber *) data[@"ca"]).doubleValue;
        _latitude = ((NSNumber *) data[@"lat"]).doubleValue;
        _longitude = ((NSNumber *) data[@"lon"]).doubleValue;
        _timestamp = data[@"timestamp"];
        _key = data[@"key"];
        _title = data[@"title"];
        _userName = data[@"username"];
        _url = data[@"url"];
        _imageUrl = data[@"imageUrl"];
        _imageHiresUrl = data[@"imageHiresUrl"];
        _externalLink = data[@"externalLink"];
        _topIcon = [self getIconName:data[@"topIcon"]];
    }
    return self;
}

- (NSString *) getIconName:(NSString *)serverIconName
{
    if (serverIconName && [serverIconName isEqualToString:@"ic_logo_mapillary"])
        return @"ic_custom_mapillary_color_logo.png";
    else
        return serverIconName;
}

- (void) downloadImage
{
    if (!_imageUrl || _imageUrl.length == 0)
        return;
    
    NSURL *imgURL = [NSURL URLWithString:_imageUrl];
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:imgURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (((NSHTTPURLResponse *)response).statusCode == 200) {
            if (data) {
                _image = [[UIImage alloc] initWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.delegate)
                        [self.delegate requestCardReload:self];
                });
            }
        }
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
        if (self.image)
            [imageCell.imageView setImage:self.image];
        else
        {
            [imageCell.imageView setImage:nil];
            
            [self downloadImage];
        }
        imageCell.usernameLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        imageCell.usernameLabel.topInset = kUserLabelInset;
        imageCell.usernameLabel.bottomInset = kUserLabelInset;
        imageCell.usernameLabel.leftInset = kUserLabelInset;
        imageCell.usernameLabel.rightInset = kUserLabelInset;
        [imageCell setUserName:self.userName];
        
        if (self.topIcon && self.topIcon.length > 0)
            [imageCell.logoView setImage:[UIImage imageNamed:self.topIcon]];
        else
            [imageCell.logoView setImage:nil];
    }
}

+ (NSString *) getCellNibId
{
    return kImageCardId;
}

@end
