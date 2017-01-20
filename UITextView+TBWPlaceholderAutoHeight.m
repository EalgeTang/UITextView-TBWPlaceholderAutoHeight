//
//  UITextView+TBWPlaceholderAutoHeight.m
//  TBWSystemAlert
//
//  Created by tangbowen on 17/1/3.
//  Copyright © 2017年 tbw. All rights reserved.
//

#import "UITextView+TBWPlaceholderAutoHeight.h"
#import <objc/runtime.h>
NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG
#define kNSLog(...)    NSLog(__VA_ARGS__)
#else
#define kNSLog(...)
#endif

/**显示占位符的textView*/
static const void *TBWPlaceholderTextViewKey = &TBWPlaceholderTextViewKey;
/**占位符*/
static const void *TBWPlaceHolderKey = &TBWPlaceHolderKey;
/**占位符颜色值*/
static const void *TBWPlaceholderColorKey = &TBWPlaceholderColorKey;
/**最大高度*/
static const void *TBWMaxHeightKey = &TBWMaxHeightKey;
/**高度回调*/
static const void *TBWTextViewHeightChangedKey = &TBWTextViewHeightChangedKey;

@implementation UITextView (TBWPlaceholderAutoHeight)

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    UITextView *placeholderView = objc_getAssociatedObject(self, TBWPlaceholderTextViewKey);
    
    if (placeholderView)
    {
        NSArray *propertys = @[@"frame", @"bounds", @"font", @"text", @"textAlignment", @"textContainerInset"];
        for (NSString *property in propertys) {
            [self removeObserver:self forKeyPath:property];
        }
    }
}

#pragma mark - set get method 

- (void)tbwSetAutoHeightMaxHeight:(CGFloat)maxHeight
            heightDidChangedBlock:(textViewHeightDidChangeBlock)heightChangedBlock
{
    self.tbw_maxHeight = maxHeight;
    self.tbw_textViewHeightDidChanged = heightChangedBlock;
    
}

- (UITextView *)tbw_placeholderTextView
{
    UITextView *placeTextView = objc_getAssociatedObject(self, TBWPlaceholderTextViewKey);
    if (!placeTextView)
    {
        //
        placeTextView = [[UITextView alloc] init];
        
        objc_setAssociatedObject(self,
                                 TBWPlaceholderTextViewKey,
                                 placeTextView,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        placeTextView.scrollEnabled = NO;
        placeTextView.showsVerticalScrollIndicator = placeTextView.showsHorizontalScrollIndicator = NO;
        placeTextView.userInteractionEnabled = NO;
        placeTextView.textColor = [UIColor lightGrayColor];
        placeTextView.backgroundColor = [UIColor clearColor];
        [self refreshPlaceholderTextView];
        [self addSubview:placeTextView];
        
        //监听文字变化
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tbw_textChange)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:nil];
        
        // kvo监听 。因为尽管已经监听了textDidChange。 但是监听不到setText；
        NSArray *propertys = @[@"frame", @"bounds", @"font", @"text", @"textAlignment", @"textContainerInset"];
        for (NSString *property in propertys)
        {
            [self addObserver:self forKeyPath:property options:NSKeyValueObservingOptionNew context:nil];
        }
        
    }
    return placeTextView;
}

/**KVO监听*/
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    [self refreshPlaceholderTextView];
    if ([keyPath isEqualToString:@"text"])
    {
        [self tbw_textChange];
    }
    
}

- (void)tbw_textChange
{
    //
    UITextView *placeholderTextView = objc_getAssociatedObject(self, TBWPlaceholderTextViewKey);
    
    if (placeholderTextView)
    {
        placeholderTextView.hidden = (self.text.length > 0 && self.text);
    }
    
    if (self.tbw_maxHeight >= self.bounds.size.height)
    { // 如果用户设置有最大maxHeight值
        
        // 计算高度
        NSInteger currentHeight = ceil([self sizeThatFits:CGSizeMake(self.bounds.size.width, MAXFLOAT)].height);
        NSInteger lastHeight = ceil(self.tbw_maxHeight + self.textContainerInset.top + self.textContainerInset.bottom);
        
        if (lastHeight != currentHeight)
        {
            self.scrollEnabled = currentHeight >= self.tbw_maxHeight;
            if (self.tbw_textViewHeightDidChanged)
            {
                self.tbw_textViewHeightDidChanged(currentHeight >= self.tbw_maxHeight ? self.tbw_maxHeight : currentHeight);
            }
        }
    }
    
    if (!self.isFirstResponder)
    {
        [self becomeFirstResponder];
    }
}

/**判断textView是否存在*/
- (BOOL)tbwPlaceholoderViewExist
{
    UITextView *placeHolderTextView = objc_getAssociatedObject(self, TBWPlaceholderTextViewKey);
    if (placeHolderTextView)
    {
        return YES;
    }
    return NO;
}

- (void)refreshPlaceholderTextView
{
    UITextView *placeholderTextView = objc_getAssociatedObject(self, TBWPlaceholderTextViewKey);
    if (placeholderTextView)
    {
        [self tbw_placeholderTextView].frame = self.bounds;
        [self tbw_placeholderTextView].font = self.font;
        [self tbw_placeholderTextView].textAlignment = self.textAlignment;
        [self tbw_placeholderTextView].textContainerInset = self.textContainerInset;
    }
}

#pragma mark - 

- (void)setTbw_placeholder:(NSString *)tbw_placeholder
{
    //
    objc_setAssociatedObject(self, TBWPlaceHolderKey, tbw_placeholder, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self tbw_placeholderTextView].text = tbw_placeholder;
}

- (NSString *)tbw_placeholder
{
    if ([self tbwPlaceholoderViewExist])
    {
        return [self tbw_placeholderTextView].text;
    }
    return nil;
}

- (void)setTbw_placeholderColor:(UIColor *)tbw_placeholderColor
{
    if ([self tbwPlaceholoderViewExist])
    {
         [self tbw_placeholderTextView].textColor = tbw_placeholderColor;
        
        objc_setAssociatedObject(self,
                                 TBWPlaceholderColorKey,
                                 tbw_placeholderColor,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else
    {
        // dlg
        kNSLog(@"UITextView+TBWPlaceholderAutoHeight ---请先设置占位符");
    }
}

- (UIColor *)tbw_placeholderColor
{
    return objc_getAssociatedObject(self, TBWPlaceholderColorKey);
}

- (void)setTbw_maxHeight:(CGFloat)tbw_maxHeight
{
    CGFloat max = tbw_maxHeight;
    // 如果传入的最大高度小于textView 本身的高度， 则让最大的高度等于本身高度
    if (tbw_maxHeight < self.frame.size.height)
    {
        max = self.frame.size.height;
    }
    objc_setAssociatedObject(self,
                            TBWMaxHeightKey ,
                             @(max),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (void)setTbw_textViewHeightDidChanged:(textViewHeightDidChangeBlock)tbw_textViewHeightDidChanged
{
    objc_setAssociatedObject(self,
                             TBWTextViewHeightChangedKey,
                             tbw_textViewHeightDidChanged,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (textViewHeightDidChangeBlock)tbw_textViewHeightDidChanged
{
    return objc_getAssociatedObject(self, TBWTextViewHeightChangedKey);
    
}
- (CGFloat)tbw_maxHeight
{
    NSNumber *max = objc_getAssociatedObject(self,
                                             TBWMaxHeightKey);
    return [max doubleValue];
}
@end

NS_ASSUME_NONNULL_END

