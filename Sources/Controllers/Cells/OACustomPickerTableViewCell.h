//
//  OACustomPickerTableViewCell.h
//  OsmAnd Maps
//
//  Created by igor on 27.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OACustomPickerTableViewCellDelegate <NSObject>

- (void)customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag;

@end

@interface OACustomPickerTableViewCell : UITableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (nonatomic) NSArray<NSString *> *dataArray;

@property (nonatomic, weak) id<OACustomPickerTableViewCellDelegate> delegate;
@end

