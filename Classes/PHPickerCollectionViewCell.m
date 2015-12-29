//
//  PHCollectionViewCell.m
//  PHPickerView
//
//  Created by Andrzej on 24/11/15.
//  Copyright © 2015 A&A.make LTD. All rights reserved.
//

#import "PHPickerCollectionViewCell.h"

@interface PHPickerCollectionViewCell ()

@end

@implementation PHPickerCollectionViewCell

- (void)initialize
{
    CGRect frame = self.bounds;
    
    self.layer.doubleSided = NO;
    self.label = [[UILabel alloc] initWithFrame:frame];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.textColor = [UIColor grayColor];
    self.label.numberOfLines = 1;
    self.label.lineBreakMode = NSLineBreakByTruncatingTail;
    self.label.highlightedTextColor = [UIColor blackColor];
    self.label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
//    self.label.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin);
    
    [self.contentView addSubview:self.label];
    
    self.roundedButton = [[PHRoundedButton alloc] initWithFrame:self.bounds buttonStyle:PHRoundedButtonDefault];
    self.roundedButton.userInteractionEnabled = NO;
    //self.roundedButton.hidden = YES;
    [self.contentView addSubview:self.roundedButton];
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

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    CATransition *transition = [CATransition animation];
    [transition setType:kCATransitionFade];
    [transition setDuration:0.15];
    [self.label.layer addAnimation:transition forKey:nil];
    
    self.label.font = self.selected ? self.highlightedFont : self.font;
    [self.roundedButton setSelected:selected];
}

//-(void)setUseRoundedButton:(BOOL)useRoundedButton
//{
//    if(useRoundedButton == _useRoundedButton)
//        return;
//    _useRoundedButton = useRoundedButton;
//    if(useRoundedButton) {
////        [self.roundedButton removeFromSuperview];
//        self.roundedButton.hidden = YES;
//        [self layoutSubviews];
//    } else {
////        [self.contentView addSubview:self.roundedButton];
//        self.roundedButton.hidden = NO;
//        [self layoutSubviews];
//    }
//}

-(void)setRoundedButtonSize:(CGSize)size
{
    if(size.width == _roundedButtonSize.width && size.height == _roundedButtonSize.height)
        return;
    _roundedButtonSize = size;
    [self layoutSubviews];
}

-(void)setInteritemSpacing:(CGFloat)interitemSpacing
{
    if(interitemSpacing == _interitemSpacing)
        return;
    _interitemSpacing = interitemSpacing;
    [self layoutSubviews];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    if(self.useRoundedButton == NO) {
        self.label.frame = self.bounds;

    } else {
        CGFloat x = self.bounds.size.width/2 - self.roundedButtonSize.width/2;
        CGRect frame = CGRectMake(x, 0, self.roundedButtonSize.width, self.roundedButtonSize.height);
        self.roundedButton.frame = frame;
        
        frame = CGRectMake(0, self.roundedButton.frame.size.height + self.interitemSpacing, self.bounds.size.width, self.bounds.size.height - self.roundedButton.frame.size.height - self.interitemSpacing);
        self.label.frame = frame;
    }
}

@end
