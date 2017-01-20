//
//  UITextView+TBWPlaceholderAutoHeight.h
//  TBWSystemAlert
//
//  Created by tangbowen on 17/1/3.
//  Copyright © 2017年 tbw. All rights reserved.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef void(^textViewHeightDidChangeBlock)(CGFloat currentTextViewHeight);

@interface UITextView (TBWPlaceholderAutoHeight)

/**占位符*/
@property (nonatomic, copy) NSString *tbw_placeholder;

/**占位符颜色*/
@property (nonatomic, strong) UIColor *tbw_placeholderColor;

/**最大高度， 需要做高度适应时设置*/
@property (nonatomic, assign) CGFloat tbw_maxHeight;

/**高度改变回调*/
@property (nonatomic, copy) textViewHeightDidChangeBlock tbw_textViewHeightDidChanged;

/**
 * 设定最大的自适应高度
 * @param maxHeight  最大高度
  * @param heightChangedBlock  高度改变之后的回调，返回textView当前内容所应该适应的高度
 * return nil
 */
- (void)tbwSetAutoHeightMaxHeight:(CGFloat)maxHeight
        heightDidChangedBlock:(textViewHeightDidChangeBlock)heightChangedBlock;

@end

NS_ASSUME_NONNULL_END;
