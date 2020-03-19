//
//  OAPointHeaderTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 16.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAPointHeaderTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *folderIcon;
@property (weak, nonatomic) IBOutlet UILabel *groupTitle;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImage;
@property (weak, nonatomic) IBOutlet UIButton *openCloseGroupButton;


@end

