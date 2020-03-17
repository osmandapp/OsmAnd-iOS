//
//  OAPublicTransportRouteCell.h
//  OsmAnd
//
//  Created by Paul on 12/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAPublicTransportShieldsView;

@interface OAPublicTransportRouteCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *topInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *detailsButton;
@property (weak, nonatomic) IBOutlet UIButton *showOnMapButton;
@property (weak, nonatomic) IBOutlet OAPublicTransportShieldsView *shieldsView;


@end
