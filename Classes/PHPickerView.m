//
//  PHPickerView.m
//  PHPickerView
//
//  Created by Andrzej on 23/11/15.
//  Copyright © 2015 A&A.make LTD. All rights reserved.
//

#import "PHPickerView.h"

#import <Availability.h>
#import "PHPickerCollectionViewCell.h"

@class PHCollectionViewLayout;


/////////
//Helpers
/////////

@protocol PHCollectionViewLayoutDelegate <NSObject>
- (PHPickerViewStyle)pickerViewStyleForCollectionViewLayout:(PHCollectionViewLayout *)layout;
@end


@interface PHCollectionViewLayout : UICollectionViewFlowLayout
@property (nonatomic, assign) id <PHCollectionViewLayoutDelegate> delegate;
@end


@interface PHPickerViewDelegateIntercepter : NSObject <UICollectionViewDelegate>
@property (nonatomic, weak) PHPickerView *pickerView;
@property (nonatomic, weak) id <UIScrollViewDelegate> delegate;
@end


//////////////
//PHPickerView
//////////////

@interface PHPickerView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHCollectionViewLayoutDelegate>

@property (nonatomic, assign) BOOL multipleSelectionPaginateScrolling;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableDictionary *selectedItems;
@property (nonatomic, strong) PHPickerViewDelegateIntercepter *intercepter;

- (CGFloat)offsetForItem:(NSUInteger)item;
- (void)didEndScrolling;
- (CGSize)sizeForString:(NSString *)string;

@end

//////////


@implementation PHPickerView

- (void)initialize
{
    self.selectedItems = [NSMutableDictionary new];
    self.font = self.font ?: [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    self.highlightedFont = self.highlightedFont ?: [UIFont fontWithName:@"HelveticaNeue" size:20];
    self.textColor = self.textColor ?: [UIColor darkGrayColor];
    self.highlightedTextColor = self.highlightedTextColor ?: [UIColor blackColor];
    self.pickerViewStyle = self.pickerViewStyle ?: PHPickerViewStyle3D;
    self.pickerViewOrientation = self.pickerViewOrientation ?: PHPickerViewOrientationHorizontal;
    self.maskDisabled = self.maskDisabled;
    
    self.useRoundedButton = NO;
    self.roundedButtonSize = CGSizeZero;
    self.multipleSelection = NO;
    self.multipleSelectionPaginateScrolling = NO;
    
    [self.collectionView removeFromSuperview];
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:[self collectionViewLayout]];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.allowsMultipleSelection = self.multipleSelection;
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[PHPickerCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([PHPickerCollectionViewCell class])];
    [self addSubview:self.collectionView];
    
    self.intercepter = [PHPickerViewDelegateIntercepter new];
    self.intercepter.pickerView = self;
    self.intercepter.delegate = self.delegate;
    self.collectionView.delegate = self.intercepter;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)dealloc
{
    self.collectionView.delegate = nil;
}

#pragma mark -

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.collectionView.collectionViewLayout = [self collectionViewLayout];
    [self scrollToFirstSelected];
    self.collectionView.layer.mask.frame = self.collectionView.bounds;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, MAX(self.font.lineHeight, self.highlightedFont.lineHeight));
}

- (CGPoint)contentOffset
{
    return self.collectionView.contentOffset;
}

#pragma mark -

- (void)setDelegate:(id<PHPickerViewDelegate>)delegate
{
    if (![_delegate isEqual:delegate]) {
        _delegate = delegate;
        self.intercepter.delegate = delegate;
    }
}

- (void)setFisheyeFactor:(CGFloat)fisheyeFactor
{
    _fisheyeFactor = fisheyeFactor;
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -MAX(MIN(self.fisheyeFactor, 1.0), 0.0);
    self.collectionView.layer.sublayerTransform = transform;
}

- (void)setMaskDisabled:(BOOL)maskDisabled
{
    _maskDisabled = maskDisabled;
    
    self.collectionView.layer.mask = maskDisabled ? nil : ({
        CAGradientLayer *maskLayer = [CAGradientLayer layer];
        maskLayer.frame = self.collectionView.bounds;
        maskLayer.colors = @[(id)[[UIColor clearColor] CGColor],
                             (id)[[UIColor blackColor] CGColor],
                             (id)[[UIColor blackColor] CGColor],
                             (id)[[UIColor clearColor] CGColor],];
        maskLayer.locations = @[@0.0, @0.33, @0.66, @1.0];
        maskLayer.startPoint = CGPointMake(0.0, 0.0);
        maskLayer.endPoint = (self.pickerViewOrientation == PHPickerViewOrientationVertical) ? CGPointMake(0.0, 1.0) : CGPointMake(1.0, 0.0);
        maskLayer;
    });
}

- (void)setPickerViewOrientation:(PHPickerViewOrientation)pickerViewOrientation
{
    _pickerViewOrientation = pickerViewOrientation;
    
    self.collectionView.collectionViewLayout = [self collectionViewLayout];
    if (!self.maskDisabled && [self.collectionView.layer.mask isKindOfClass:[CAGradientLayer class]]) {
        CAGradientLayer *maskLayer = (CAGradientLayer *)self.collectionView.layer.mask;
        maskLayer.endPoint = (self.pickerViewOrientation == PHPickerViewOrientationVertical) ? CGPointMake(0.0, 1.0) : CGPointMake(1.0, 0.0);
    }
}

-(void)setMultipleSelection:(BOOL)multipleSelection
{
    _multipleSelection = multipleSelection;
    self.collectionView.allowsMultipleSelection = multipleSelection;
}

- (void)setMutlipleSelection:(BOOL)multipleSelection paginateScrolling:(BOOL)multipleSelectionPaginateScrolling
{
    self.multipleSelection = multipleSelection;
    self.multipleSelectionPaginateScrolling = multipleSelectionPaginateScrolling;
}


#pragma mark -

- (PHCollectionViewLayout *)collectionViewLayout
{
    PHCollectionViewLayout *layout = [PHCollectionViewLayout new];
    layout.delegate = self;
    switch (self.pickerViewOrientation) {
        case PHPickerViewOrientationVertical:
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
            break;
        case PHPickerViewOrientationHorizontal:
        default:
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            break;
    }
    return layout;
}

- (CGSize)sizeForString:(NSString *)string
{
    CGSize size;
    CGSize highlightedSize;
#ifdef __IPHONE_7_0
    size = [string sizeWithAttributes:@{NSFontAttributeName: self.font}];
    highlightedSize = [string sizeWithAttributes:@{NSFontAttributeName: self.highlightedFont}];
#else
    size = [string sizeWithFont:self.font];
    highlightedSize = [string sizeWithFont:self.highlightedFont];
#endif
    return CGSizeMake(ceilf(MAX(size.width, highlightedSize.width)), ceilf(MAX(size.height, highlightedSize.height)));
}



#pragma mark -

- (void)reloadData
{
    [self invalidateIntrinsicContentSize];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView reloadData];
    [self scrollToFirstSelected];
}

- (CGFloat)offsetForItem:(NSUInteger)item
{
    NSAssert(item < [self.collectionView numberOfItemsInSection:0],
             @"item out of range; '%lu' passed, but the maximum is '%lu'", (long unsigned)item, (long unsigned)[self.collectionView numberOfItemsInSection:0]);
    
    CGFloat offset = 0.0;
    
    for (NSInteger i = 0; i < item; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        CGSize cellSize = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:indexPath];
        if (self.pickerViewOrientation == PHPickerViewOrientationVertical) {
            offset += cellSize.height;
            
        } else {
            offset += cellSize.width;
        }
    }
    
    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    CGSize firstSize = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:firstIndexPath];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    CGSize selectedSize = [self collectionView:self.collectionView layout:self.collectionView.collectionViewLayout sizeForItemAtIndexPath:selectedIndexPath];
    if (self.pickerViewOrientation == PHPickerViewOrientationVertical) {
        offset -= (firstSize.height - selectedSize.height) / 2;
    } else {
        offset -= (firstSize.width - selectedSize.width) / 2;
    }
    
    return offset;
}

/**
 ScrollPosition works only in FlatStyle
 */
-(void)scrollToItem:(NSUInteger)item animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition
{
    switch (self.pickerViewStyle) {
        case PHPickerViewStyleFlat: {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:scrollPosition animated:animated];
            break;
        }
        case PHPickerViewStyle3D: {
            if (self.pickerViewOrientation == PHPickerViewOrientationVertical) {
                [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, [self offsetForItem:item])
                                             animated:animated];
            } else {
                [self.collectionView setContentOffset:CGPointMake([self offsetForItem:item], self.collectionView.contentOffset.y)
                                             animated:animated];
            }
            break;
        }
        default: break;
    }
}

- (void)scrollToItem:(NSUInteger)item animated:(BOOL)animated
{
    if (self.pickerViewOrientation == PHPickerViewOrientationVertical)
        [self scrollToItem:item animated:animated scrollPosition:(UICollectionViewScrollPositionCenteredVertically)];
    else
        [self scrollToItem:item animated:animated scrollPosition:(UICollectionViewScrollPositionCenteredHorizontally)];
}

-(void)scrollToFirstSelected
{
    NSUInteger numberOfItems = [self.dataSource numberOfItemsInPickerView:self];
    if (numberOfItems) {
        NSArray *sortedKeys = [[self.selectedItems allKeys] sortedArrayUsingSelector: @selector(compare:)];
        if(sortedKeys.count) {
            NSString *firstKey = sortedKeys.firstObject;
            NSAssert([firstKey isKindOfClass:NSString.class], @"Selected items - wrong key class");
            NSUInteger firstSelectedItem = firstKey.intValue;
            if(firstSelectedItem < numberOfItems)
                [self scrollToItem:firstSelectedItem animated:NO];
        }
    }
}

//////////

- (BOOL)isItemSelected:(NSUInteger)item
{
    NSNumber *value = [self.selectedItems objectForKey:[NSString stringWithFormat:@"%lu", item]];
    BOOL isSelected = value != nil;
    return isSelected;
}

- (void)setItem:(NSUInteger)item selected:(BOOL)selected
{
    if(self.multipleSelection) {
        if(selected)
            [self.selectedItems setObject:@(YES) forKey:[NSString stringWithFormat:@"%lu", item]];
        else
            [self.selectedItems removeObjectForKey:[NSString stringWithFormat:@"%lu", item]];
        
    } else {
        [self.selectedItems removeAllObjects];
        if(selected)
            [self.selectedItems setObject:@(YES) forKey:[NSString stringWithFormat:@"%lu", item]];
    }
}

//////////

/**
 Sets item select without notifying delegate and scrolling to the corresponding cell. Usefull to prevent infinite loop, if delegate wishes to change selections in delegate callback.
 */
-(void)selectItemSilently:(NSInteger)item
{
    [self selectItem:item animated:NO notifyDelegateAndScrollToItem:NO];
}

/**
 Sets item deselected without notifying delegate and scrolling to the corresponding cell. Usefull to prevent infinite loop, if delegate wishes to change selections in delegate callback.
 */
-(void)deselectItemSilently:(NSInteger)item
{
    [self deselectItem:item animated:NO notifyDelegateAndScrollToItem:NO];
}

- (void)setInitialItemsSelected:(NSArray *)items
{
    for (NSNumber *item in items) {
        [self setItem:item.integerValue selected:YES];
    }
}

- (void)selectItem:(NSUInteger)item animated:(BOOL)animated
{
    [self selectItem:item animated:animated notifyDelegateAndScrollToItem:YES];
}

- (void)deselectItem:(NSUInteger)item animated:(BOOL)animated
{
    [self deselectItem:item animated:animated notifyDelegateAndScrollToItem:YES];
}

- (void)selectItem:(NSUInteger)item animated:(BOOL)animated notifyDelegateAndScrollToItem:(BOOL)notifyDelegateAndScrollToItem
{
    [self setItem:item selected:YES];
    
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]
                                      animated:animated
                                scrollPosition:UICollectionViewScrollPositionNone];
    
    if(notifyDelegateAndScrollToItem) {
        [self scrollToItem:item animated:animated];
        if ([self.delegate respondsToSelector:@selector(pickerView:didSelectItem:)])
            [self.delegate pickerView:self didSelectItem:item];
    }
}

- (void)deselectItem:(NSUInteger)item animated:(BOOL)animated notifyDelegateAndScrollToItem:(BOOL)notifyDelegateAndScrollToItem
{
    [self setItem:item selected:NO];
    [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] animated:animated];
    
    if(notifyDelegateAndScrollToItem) {
        [self scrollToItem:item animated:animated];
        if ([self.delegate respondsToSelector:@selector(pickerView:didDeselectItem:)])
            [self.delegate pickerView:self didDeselectItem:item];
    }
}


- (void)didEndScrolling
{
    switch (self.pickerViewStyle) {
        case PHPickerViewStyleFlat: {
            if(self.multipleSelection == NO) {
                CGPoint center = [self convertPoint:self.collectionView.center toView:self.collectionView];
                NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:center];
                [self selectItem:indexPath.item animated:YES];
                
            } else if(self.multipleSelectionPaginateScrolling) {
                CGPoint left = [self convertPoint:self.collectionView.frame.origin toView:self.collectionView];
                NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:left];
                [self scrollToItem:indexPath.item animated:YES scrollPosition:(UICollectionViewScrollPositionLeft)];
            }
            break;
        }
            
        case PHPickerViewStyle3D: {
            if ([self.dataSource numberOfItemsInPickerView:self]) {
                for (NSUInteger i = 0; i < [self collectionView:self.collectionView numberOfItemsInSection:0]; i++) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                    PHPickerCollectionViewCell *cell = (PHPickerCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    if (self.pickerViewOrientation == PHPickerViewOrientationVertical) {
                        if ([self offsetForItem:i] + cell.bounds.size.height / 2 > self.collectionView.contentOffset.y) {
                            if(self.multipleSelection == NO)
                                [self selectItem:i animated:YES];
                            break;
                        }
                    } else {
                        if ([self offsetForItem:i] + cell.bounds.size.width / 2 > self.collectionView.contentOffset.x) {
                            if(self.multipleSelection == NO)
                                [self selectItem:i animated:YES];
                            break;
                        }
                    }
                }
            }
            break;
        }
        default: break;
    }
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return ([self.dataSource numberOfItemsInPickerView:self] > 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.dataSource numberOfItemsInPickerView:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseId = NSStringFromClass([PHPickerCollectionViewCell class]);
    
    PHPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseId forIndexPath:indexPath];
    
    const BOOL selected = [self isItemSelected:indexPath.item];
    
    NSString *title = nil;
    NSString *selectedTitle = nil;
    if([self.dataSource respondsToSelector:@selector(pickerView:selectedTitleForItem:)])
        selectedTitle = [self.dataSource pickerView:self selectedTitleForItem:indexPath.item];
    if ([self.dataSource respondsToSelector:@selector(pickerView:titleForItem:)])
        title = [self.dataSource pickerView:self titleForItem:indexPath.item];
    
    cell.title = title;
    cell.selectedTitle = selectedTitle;
    
    cell.label.text = selected ? selectedTitle : title;
    cell.label.textColor = self.textColor;
    cell.label.highlightedTextColor = self.highlightedTextColor;
    cell.label.font = self.font;
    cell.font = self.font;
    cell.highlightedFont = self.highlightedFont;
    
    cell.useRoundedButton = self.useRoundedButton;
    cell.roundedButtonSize = self.roundedButtonSize;
    
    if ([self.delegate respondsToSelector:@selector(pickerView:marginForItem:)])
        cell.margin = [self.delegate pickerView:self marginForItem:indexPath.item];
    else
        cell.margin = CGSizeZero;
    
    if(self.useRoundedButton) {
        if([self.dataSource respondsToSelector:@selector(pickerView:roundedButtonAppearanceIdentifierForItem:)]) {
            NSString *roundedAppearanceId = [self.dataSource pickerView:self roundedButtonAppearanceIdentifierForItem:indexPath.item];
            if(roundedAppearanceId.length) {
                [cell.roundedButton setAppearanceIdentifier:roundedAppearanceId];
            }
        }
    }
    
    [cell layoutSubviews];
    
    if(selected) {
        [cell setSelected:selected animated:YES];
        //Without it, UICollectionView blocked and cells will not be deselected ever.
        //http://stackoverflow.com/a/17812116/3464670
        [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:(UICollectionViewScrollPositionNone)];
    }
    
    if([self.delegate respondsToSelector:@selector(pickerView:configureCell:forItem:)]) {
        [self.delegate pickerView:self configureCell:&cell forItem:indexPath.item];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = (self.pickerViewOrientation == PHPickerViewOrientationHorizontal) ? CGSizeMake(self.interitemSpacing, collectionView.bounds.size.height) : CGSizeMake(collectionView.bounds.size.width, self.interitemSpacing);
    
    CGSize labelSize = size;
    CGSize roundedButtonSize = size;
    
    if([self.dataSource respondsToSelector:@selector(pickerView:titleForItem:)]) {
        NSString *title = [self.dataSource pickerView:self titleForItem:indexPath.item];
        
        NSString *selectedTitle = @"";
        if([self.dataSource respondsToSelector:@selector(pickerView:selectedTitleForItem:)])
            selectedTitle = [self.dataSource pickerView:self selectedTitleForItem:indexPath.item];
        
        //calculate label size
        if (title) {
            CGFloat textSize = 0.;
            if (self.pickerViewOrientation == PHPickerViewOrientationHorizontal) {
                textSize = MAX([self sizeForString:title].width, [self sizeForString:selectedTitle].width);
                labelSize.width += textSize;
            } else {
                textSize = MAX([self sizeForString:title].height, [self sizeForString:selectedTitle].height);
                labelSize.height += textSize;
            }
        }
    }
    
    if(self.useRoundedButton == NO)
        return labelSize;
    
    //pick the bigger size
    if(self.pickerViewOrientation == PHPickerViewOrientationHorizontal) {
        roundedButtonSize.width += self.roundedButtonSize.width;
        size = (labelSize.width > roundedButtonSize.width) ? labelSize : roundedButtonSize;
        
    } else {
        roundedButtonSize.height += self.roundedButtonSize.height;
        size = (labelSize.height > roundedButtonSize.height) ? labelSize : roundedButtonSize;
    }
    
    //add margin
    if ([self.delegate respondsToSelector:@selector(pickerView:marginForItem:)]) {
        CGSize margin = [self.delegate pickerView:self marginForItem:indexPath.item];
        if (self.pickerViewOrientation == PHPickerViewOrientationHorizontal) {
            size.width += margin.width * 2;
        } else {
            size.height += margin.height * 2;
        }
    }
    
    return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if(self.centerFirstItem == NO)
        return UIEdgeInsetsZero;
    
    //create insets to center first item
    NSInteger number = [self collectionView:collectionView numberOfItemsInSection:section];
    NSIndexPath *firstIndexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    CGSize firstSize = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:firstIndexPath];
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:number - 1 inSection:section];
    CGSize lastSize = [self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:lastIndexPath];
    if (self.pickerViewOrientation == PHPickerViewOrientationVertical) {
        return UIEdgeInsetsMake((collectionView.bounds.size.height - firstSize.height) / 2, 0,
                                (collectionView.bounds.size.height - lastSize.height) / 2, 0);
    } else {
        return UIEdgeInsetsMake(0, (collectionView.bounds.size.width - firstSize.width) / 2,
                                0, (collectionView.bounds.size.width - lastSize.width) / 2);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectItem:indexPath.item animated:YES];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [self deselectItem:indexPath.item animated:YES];
}

#pragma mark -

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    
    if (!scrollView.isTracking) [self didEndScrolling];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    
    if (!decelerate) [self didEndScrolling];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)])
        [self.delegate scrollViewDidScroll:scrollView];
    
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    self.collectionView.layer.mask.frame = self.collectionView.bounds;
    [CATransaction commit];
}

#pragma mark -

- (PHPickerViewStyle)pickerViewStyleForCollectionViewLayout:(PHCollectionViewLayout *)layout
{
    return self.pickerViewStyle;
}

@end

//////////
//PHCollectionViewLayout
//////////

@interface PHCollectionViewLayout ()

@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGFloat midX;
@property (nonatomic, assign) CGFloat midY;
@property (nonatomic, assign) CGFloat maxAngle;

@end

//////////

@implementation PHCollectionViewLayout

- (id)init
{
    self = [super init];
    if (self) {
        self.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        self.minimumLineSpacing = 0.0;
    }
    return self;
}

- (void)prepareLayout
{
    CGRect visibleRect = (CGRect){self.collectionView.contentOffset, self.collectionView.bounds.size};
    self.midX = CGRectGetMidX(visibleRect);
    self.midY = CGRectGetMidY(visibleRect);
    self.width = CGRectGetWidth(visibleRect) / 2;
    self.height = CGRectGetHeight(visibleRect) / 2;
    self.maxAngle = M_PI_2;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    switch ([self.delegate pickerViewStyleForCollectionViewLayout:self]) {
        case PHPickerViewStyleFlat: {
            return attributes; break;
        }
        case PHPickerViewStyle3D: {
            if (self.scrollDirection == UICollectionViewScrollDirectionVertical) {
                CGFloat distance = CGRectGetMidY(attributes.frame) - self.midY;
                CGFloat currentAngle = self.maxAngle * distance / self.height / M_PI_2;
                CATransform3D transform = CATransform3DIdentity;
                transform = CATransform3DTranslate(transform, 0, distance, -self.height);
                transform = CATransform3DRotate(transform, currentAngle, 1, 0, 0);
                transform = CATransform3DTranslate(transform, 0, 0, self.height);
                attributes.transform3D = transform;
                attributes.alpha = (ABS(currentAngle) < self.maxAngle);
            } else {
                CGFloat distance = CGRectGetMidX(attributes.frame) - self.midX;
                CGFloat currentAngle = self.maxAngle * distance / self.width / M_PI_2;
                CATransform3D transform = CATransform3DIdentity;
                transform = CATransform3DTranslate(transform, -distance, 0, -self.width);
                transform = CATransform3DRotate(transform, currentAngle, 0, 1, 0);
                transform = CATransform3DTranslate(transform, 0, 0, self.width);
                attributes.transform3D = transform;
                attributes.alpha = (ABS(currentAngle) < self.maxAngle);
            }
            return attributes; break;
        }
        default: return nil; break;
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    switch ([self.delegate pickerViewStyleForCollectionViewLayout:self]) {
        case PHPickerViewStyleFlat: {
            return [super layoutAttributesForElementsInRect:rect];
            break;
        }
        case PHPickerViewStyle3D: {
            NSMutableArray *attributes = [NSMutableArray array];
            if ([self.collectionView numberOfSections]) {
                for (NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                    [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
                }
            }
            return attributes;
            break;
        }
        default: return nil; break;
    }
}

@end

//////////

@implementation PHPickerViewDelegateIntercepter

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.pickerView respondsToSelector:aSelector]) return self.pickerView;
    if ([self.delegate respondsToSelector:aSelector]) return self.delegate;
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self.pickerView respondsToSelector:aSelector]) return YES;
    if ([self.delegate respondsToSelector:aSelector]) return YES;
    return [super respondsToSelector:aSelector];
}

@end