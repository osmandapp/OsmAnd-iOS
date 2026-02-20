//
//  OASegmentedSlider.h
//  OsmAnd
//
//  Created by Skalii on 07.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASlider.h"

@protocol OASegmentedSliderDelegate <NSObject>

- (void)onSliderValueChanged;
- (void)onSliderFinishEditing;

@end

@interface OASegmentedSlider : OASlider

@property (weak, nonatomic) id<OASegmentedSliderDelegate> delegate;

@property (nonatomic) NSInteger selectedMark;
@property (nonatomic) NSInteger selectingMark;
@property (nonatomic) CGFloat currentMarkX;
@property (nonatomic) CGFloat maximumForCurrentMark;

@property (nonatomic) NSInteger stepsAmountWithoutDrawMark;

- (NSInteger)getIndexForOptionStepsAmountWithoutDrawMark;
- (void)clearTouchEventsUpInsideUpOutside;

- (void)setNumberOfMarks:(NSInteger)numberOfMarks;
- (void)setNumberOfMarks:(NSInteger)numberOfMarks
  additionalMarksBetween:(NSInteger)additionalMarksBetween;

- (void)makeCustom;
- (void)setUsingExtraThumbInset:(BOOL)isUsing;

- (NSString *)getSelectingMarkTitleTextAtIndex:(NSInteger)index;
- (NSInteger)getMarksCount;

@end
