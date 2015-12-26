//
//  PHPickerView.h
//  PHPickerView
//
//  Created by Andrzej on 23/11/15.
//  Copyright © 2015 A&A.make LTD. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "PHPickerCollectionViewCell.h"


typedef NS_ENUM(NSInteger, PHPickerViewStyle) {
    PHPickerViewStyle3D = 1,
    PHPickerViewStyleFlat
};

typedef NS_ENUM(NSUInteger, PHPickerViewOrientation) {
    PHPickerViewOrientationHorizontal = 1,
    PHPickerViewOrientationVertical,
};


@class PHPickerView;

/////////////////////

@protocol PHPickerViewDataSource <NSObject>

@required
- (NSUInteger)numberOfItemsInPickerView:(PHPickerView *)pickerView;
@optional

/**
 @brief Use it to configure properly dequeued cell.
 @discussion  Called after titleForItem: and imageForItem:, so you can use them to have initially configured cell as a starting point.
*/
- (void)pickerView:(PHPickerView *)pickerView configureCell:(PHPickerCollectionViewCell **)cell forItem:(NSInteger)item;

/*
 One of the below is called to generate items, beginning with the top-most data source method. Method pickerView:configureCell:forItem is called after those methods, so you can e.g. provide a title and then configure the cell, or just configure it straight away.
 */
- (NSString *)pickerView:(PHPickerView *)pickerView titleForItem:(NSInteger)item;
- (UIImage *)pickerView:(PHPickerView *)pickerView imageForItem:(NSInteger)item;


@end

/////////////////////

@protocol PHPickerViewDelegate <UIScrollViewDelegate>
@optional
- (void)pickerView:(PHPickerView *)pickerView didSelectItem:(NSInteger)item;
- (void)pickerView:(PHPickerView *)pickerView didDeselectItem:(NSInteger)item;
- (CGSize)pickerView:(PHPickerView *)pickerView marginForItem:(NSInteger)item;
- (void)pickerView:(PHPickerView *)pickerView configureLabel:(UILabel * const)label forItem:(NSInteger)item;
@end

/////////////////////

@interface PHPickerView : UIView

@property (nonatomic, weak) id <PHPickerViewDataSource> dataSource;
@property (nonatomic, weak) id <PHPickerViewDelegate> delegate;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIFont *highlightedFont;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *highlightedTextColor;
@property (nonatomic, assign) CGFloat interitemSpacing;
@property (nonatomic, assign) CGFloat fisheyeFactor; // 0...1; slight value recommended such as 0.0001
@property (nonatomic, assign, getter=isMaskDisabled) BOOL maskDisabled;
@property (nonatomic, assign) PHPickerViewStyle pickerViewStyle;
@property (nonatomic, assign) PHPickerViewOrientation pickerViewOrientation;
//@property (nonatomic, assign, readonly) NSUInteger selectedItem;
@property (nonatomic, assign, readonly) CGPoint contentOffset;

@property (nonatomic, assign) BOOL multipleSelection;

- (void)reloadData;
- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated;
- (void)selectItem:(NSUInteger)item animated:(BOOL)animated;

@end