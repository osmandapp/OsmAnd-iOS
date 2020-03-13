//
//  OAQPickerWithEntryElement.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialog.h>
#import <QRadioElement.h>

@interface OAQStringPickerElement : QRadioElement

- (instancetype)initWithItems:(NSArray*)stringArray
                     selected:(NSInteger)selected
                        title:(NSString*)title;
- (instancetype)initWithItems:(NSArray*)stringArray
                     selected:(NSInteger)selected
                        title:(NSString*)title
                 newItemTitle:(NSString*)newItemTitle
                 newItemPlaceholder:(NSString*)newItemPlaceholder;

@end
