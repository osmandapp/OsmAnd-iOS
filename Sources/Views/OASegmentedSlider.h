//
//  OASegmentedSlider.h
//  OsmAnd
//
//  Created by Skalii on 07.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASlider.h"

static const NSInteger kDayFiveMinutesMarksCount = 289;

@interface OASegmentedSlider : OASlider

@property (nonatomic) NSInteger selectedMark;
@property (nonatomic) CGFloat currentMarkX;
@property (nonatomic) CGFloat maximumForCurrentMark;

@property (nonatomic) NSInteger stepsAmountWithoutDrawMark;

- (NSInteger)getIndexForOptionStepsAmountWithoutDrawMark;
- (void)clearTouchEventsUpInsideUpOutside;

- (void)setNumberOfMarks:(NSInteger)numberOfMarks
  additionalMarksBetween:(NSInteger)additionalMarksBetween;

- (void)makeCustom;
- (void)setUsingExtraThumbInset:(BOOL)isUsing;

@end
