//
//  OAQStringPickerElement.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/8/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAQStringPickerElement.h"

@interface OAQStringPickerElement () <QuickDialogEntryElementDelegate>
@end

#define kNewItemEntryElementKey @"newItemEntryElement"

@implementation OAQStringPickerElement
{
    NSString* _newItemTitle;
    NSString* _newItemPlaceholder;
}

- (instancetype)initWithItems:(NSArray*)stringArray selected:(NSInteger)selected title:(NSString*)title
{
    self = [super init];
    if (self) {
        _newItemTitle = [@"New " stringByAppendingString:title];
        _newItemPlaceholder = nil;

        self.grouped = YES;
        self.title = title;
        self.items = stringArray;
        self.selected = selected;
    }
    return self;
}

- (instancetype)initWithItems:(NSArray*)stringArray
                     selected:(NSInteger)selected
                        title:(NSString*)title
                 newItemTitle:(NSString*)newItemTitle
           newItemPlaceholder:(NSString*)newItemPlaceholder
{
    self = [super init];
    if (self) {
        _newItemTitle = [newItemTitle copy];
        _newItemPlaceholder = [newItemPlaceholder copy];

        self.grouped = YES;
        self.title = title;
        self.items = stringArray;
        self.selected = selected;
    }
    return self;
}

- (void)createElements
{
    [super createElements];

    // Create additional section with entry element
    QSection* entrySection = [[QSection alloc] init];
    [self addSection:entrySection];
    QEntryElement* entryElement = [[QEntryElement alloc] initWithTitle:_newItemTitle
                                                                 Value:nil
                                                           Placeholder:_newItemPlaceholder];
    entryElement.enablesReturnKeyAutomatically = YES;
    entryElement.delegate = self;
    entryElement.key = kNewItemEntryElementKey;
    [entrySection addElement:entryElement];
}

- (void)updateCell:(QEntryTableViewCell*)cell selectedValue:(id)selectedValue
{
    if (selectedValue == nil)
        selectedValue = self.selectedValue;
    [super updateCell:cell selectedValue:selectedValue];

    if (self.title == nil)
    {
        cell.textField.textColor = self.enabled ? self.appearance.valueColorEnabled : self.appearance.valueColorDisabled;
    }
    else
    {
        cell.textField.textColor = self.enabled ? self.appearance.entryTextColorEnabled : self.appearance.entryTextColorDisabled;
    }
}

- (NSObject*)selectedValue
{
    NSObject* value = [super selectedValue];
    if (value == nil)
    {
        QEntryElement* entryElement = (QEntryElement*)[self.parentSection.rootElement elementWithKey:kNewItemEntryElementKey];
        return [entryElement.textValue copy];
    }

    return value;
}

-(id)selectedItem
{
    id item = [super selectedItem];
    if (item == nil)
    {
        QEntryElement* entryElement = (QEntryElement*)[self.parentSection.rootElement elementWithKey:kNewItemEntryElementKey];
        return [entryElement.textValue copy];
    }

    return item;
}

#pragma mark - QuickDialogEntryElementDelegate

- (void)QEntryDidEndEditingElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell
{
    if (![element.key isEqualToString:kNewItemEntryElementKey])
        return;

    // In case custom item is entered, deselect any selection
    NSString* value = element.textValue;
    if (value == nil || [value length] == 0)
        return;
    self.selected = -1;

    // Close the root element
    QuickDialogController* rootController = (QuickDialogController*)self.controller;
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:rootController
                                   selector:@selector(popToPreviousRootElement)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark -

@end
