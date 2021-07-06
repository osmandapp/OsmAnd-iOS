//
//  OAIPFSImageCard.mm
//  OsmAnd
//
//  Created by Skalii on 06.07.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAIPFSImageCard.h"

@implementation OAIPFSImageCard

- (id)initWithData:(NSDictionary *)data
{
    self = [super initWithData:data];
    if (self)
    {
        NSString *imageUrl = [NSString stringWithFormat:@"%@api/ipfs/image?cid=%@&hash=%@&ext=%@", OPR_BASE_URL, data[@"cid"], data[@"hash"], data[@"extension"]];
        self.url = imageUrl;
        self.imageHiresUrl = self.url;
        self.imageUrl = self.url;
        self.topIcon = @"ic_custom_logo_openplacereviews.png";
    }
    return self;
}

- (void)onCardPressed:(OAMapPanelViewController *) mapPanel
{
    NSString *cardUrl = [self getSuitableUrl];
    if (cardUrl && cardUrl.length > 0)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cardUrl]];
}

@end
