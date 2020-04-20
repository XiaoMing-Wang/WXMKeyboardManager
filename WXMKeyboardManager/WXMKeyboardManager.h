//
//  WXMKeyboardManager.h
//
//  Created by wq on 2019/4/21.
//  Copyright © 2019年 wq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/* 判断参照物 默认WXMReferenceSelf */
typedef NS_ENUM(NSUInteger,WXMReference) {
    WXMReferenceSelf = 0,
    WXMReferenceNone,
    WXMReferenceNextTF,
    WXMReferenceSureButton
};

/* 需要忽略的机型 例：WXMIgnoreModels_5 则5以上机型没有效果 */
typedef NS_ENUM(NSUInteger,WXMIgnoreModels) {
    WXMIgnoreModels_4 = 0,
    WXMIgnoreModels_5,
    WXMIgnoreModels_8,
    WXMIgnoreModels_8p,
    WXMIgnoreModels_x,
};
@protocol WXMKeyboardProtocol<NSObject>
@optional
- (WXMReference)wxmKeyboardReference:(UITextField *)textField;
@end

@interface WXMKeyboardManager : NSObject

/** 开启 默认YES */
@property (nonatomic, assign) BOOL enabled;

/** 回滚 是否回滚 默认YES */
@property (nonatomic, assign) BOOL rollback;

/** 是否添加点击收回事件 默认YES */
@property (nonatomic, assign) BOOL clickBlack;

/** 是否键盘确定键自动更改(next sure) 默认NO */
@property (nonatomic, assign) BOOL nextOptions;

/** 底部距离 */
@property (nonatomic, assign) CGFloat bottomSpace;

/** 忽略的机型 向上兼容 */
@property (nonatomic, assign) WXMIgnoreModels ignoreModels;

/** 确认按钮 nil默认WXMReferenceSel模式 */
@property (nonatomic, weak) UIView * nextSureView;

/** 代理 不设置默认WXMReferenceSelf模式 */
@property (nonatomic, weak) id <WXMKeyboardProtocol>delegate;

/** 初始化 underView 移动的试图 self.view 或 scrollerview */
/** 如果用自动布局 用scrollerview作为底视图 */
+ (instancetype)keyboardManagerWithUnder:(UIView *)underView;

@end
