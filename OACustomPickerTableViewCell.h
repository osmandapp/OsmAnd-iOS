//
//  OACustomPickerTableViewCell.h
//  OsmAnd Maps
//
//  Created by igor on 27.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OACustomPickerTableViewCell : UITableViewCell <UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (nonatomic) NSArray *dataArray;
@end

