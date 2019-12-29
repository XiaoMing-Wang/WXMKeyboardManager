//
//  WXMKeyboardManager.m
//
//  Created by wq on 2019/4/21.
//  Copyright © 2019年 wq. All rights reserved.
//
#define MaxKeyBoardH 282 /**  键盘最大高度 */
#define KWindow [[[UIApplication sharedApplication] delegate] window]
#define KNotificationCenter [NSNotificationCenter defaultCenter]
#define KHeight [UIScreen mainScreen].bounds.size.height
#import "WXMKeyboardManager.h"

@interface WXMKeyboardManager ()<UIScrollViewDelegate>
@property (nonatomic, weak) UIView *underView;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) UIControl *responseView;

@property (nonatomic, strong) NSMutableArray *textFieldArray;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *judgeLocationBottom;
@property (nonatomic, weak) UITextField *currentTextField;
@property (nonatomic, weak) UITextField *nextTextField;

@property (nonatomic, assign) BOOL animation;
@property (nonatomic, assign) BOOL loadFinished;
@property (nonatomic, assign) BOOL showKeyboard;
@property (nonatomic, assign) BOOL responsing;
@property (nonatomic, assign) BOOL needDisplacement;
@property (nonatomic, assign)  WXMReference referenceType;
@property (nonatomic, assign) CGFloat locationBottom;
@property (nonatomic, assign) CGFloat nextSureBottom;
@property (nonatomic, assign) CGFloat keyboardTop;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) CGRect oldRect;
@end


@implementation WXMKeyboardManager

+ (instancetype)keyboardManagerWithUnder:(UIView *)underView {
    WXMKeyboardManager * manager = [WXMKeyboardManager new];
    [manager initializationPperation:underView];
    return manager;
}

/** 初始化 */
- (void)initializationPperation:(UIView *)underView  {
    self.underView = underView;
    self.oldRect = self.underView.frame;
    self.textFieldArray = @[].mutableCopy;
    self.rollback = NO;
    self.enabled = YES;
    self.needDisplacement = YES;
    self.bottomSpace = .25;
    if ([underView isKindOfClass:[UIScrollView class]]) {
        self.scrollView = (UIScrollView *)underView;
    }
    self.clickBlack = YES;

    /* 递归获取所有的textField */
    [self getParentViewOfTextField:underView];
    if (self.textFieldArray.count == 0) return;
    
    /** 排序 */
    [self quickExhautArray];
    
    /** 计算底部距离 */
    [self calculationPosition];
    self.nextOptions = YES;
    
    [KNotificationCenter addObserver:self selector:@selector(keyBoardWillShow:)
                                name:UIKeyboardWillShowNotification object:nil];
    [KNotificationCenter addObserver:self selector:@selector(keyBoardWillHide:)
                                name:UIKeyboardWillHideNotification object:nil];
}


/* 递归获取所有的textField */
- (void)getParentViewOfTextField:(UIView *)supView {
    for (UIView *subView in supView.subviews) {
        if ([subView isKindOfClass:[UITextField class]]) {
            [self.textFieldArray addObject:subView];
        } else if(subView.subviews.count > 0) {
            [self getParentViewOfTextField:subView];
        }
    }
}

/** 排序 */
- (void)quickExhautArray  {
    for (int i = 0; i < self.textFieldArray.count; ++i) {
        for (int j = 0; j < self.textFieldArray.count - 1 - i; ++j) {
            UITextField * aTextField = self.textFieldArray[j];
            UITextField * bTextField = self.textFieldArray[j + 1];
            CGRect aRect = [aTextField convertRect:aTextField.bounds toView:KWindow];
            CGRect bRect = [bTextField convertRect:bTextField.bounds toView:KWindow];
            if (aRect.origin.y > bRect.origin.y) {
                [self.textFieldArray exchangeObjectAtIndex:j withObjectAtIndex:j + 1];
            }
        }
    }
}

/** 计算底部位置 */
- (void)calculationPosition {
    self.judgeLocationBottom = @[].mutableCopy;
    [self.textFieldArray enumerateObjectsUsingBlock:^(UITextField* obj, NSUInteger idx, BOOL *stop) {
        CGRect rect = [obj convertRect:obj.bounds toView:KWindow];
        CGFloat locationBottom = rect.origin.y + obj.frame.size.height;
        [self.judgeLocationBottom addObject:@(locationBottom)];
    }];
}

- (void)setNextSureView:(UIView *)nextSureView {
    _nextSureView = nextSureView;
    CGRect rect = [nextSureView convertRect:nextSureView.bounds toView:KWindow];
    CGFloat locationBottom = rect.origin.y + nextSureView.frame.size.height;
    self.nextSureBottom = locationBottom;
}

#pragma mark  ----------------------------------- 监听

/** 键盘弹出 */
- (void)keyBoardWillShow:(NSNotification *)notification {
    if (!self.enabled) return;
    if (!self.needDisplacement) return;
    
    self.referenceType = WXMReferenceSelf;
    if (self.delegate && [self.delegate respondsToSelector:@selector(wxmKeyboardReference:)]) {
        self.referenceType = [self.delegate wxmKeyboardReference:self.currentTextField];
    }
    
    /** 不偏移 */
    if (self.referenceType == WXMReferenceNone) return;
    
    
    /** 根据自己判断 */
    void (^accordingSelf)(void) = ^(void) {
        NSInteger idex = [self.textFieldArray indexOfObject:self.currentTextField];
        if (self.judgeLocationBottom.count == self.textFieldArray.count) {
            self.locationBottom = [self.judgeLocationBottom[idex] floatValue];
            [self keyBoardSelfTextField:notification];
        }
    };
    
    /** 根据自身判断 */
    if (self.referenceType == WXMReferenceSelf) accordingSelf();
    
    /** 根据下一个tf */
    if (self.referenceType == WXMReferenceNextTF) {
        if (self.nextTextField == nil) accordingSelf();
        if (self.nextTextField != nil) {
            NSInteger idex = [self.textFieldArray indexOfObject:self.nextTextField];
            if (self.judgeLocationBottom.count == self.textFieldArray.count) {
                self.locationBottom = [self.judgeLocationBottom[idex] floatValue];
                [self keyBoardSelfTextField:notification];
            }
        }
    }

    /** 根据确认按钮  */
    if (self.referenceType == WXMReferenceSureButton) {
        if (self.nextSureView == nil) accordingSelf();
        if (self.nextSureView != nil) {
            self.locationBottom = self.nextSureBottom + 10 + self.bottomSpace;
            [self keyBoardSelfTextField:notification];
        }
    }
}

/**  根据自己偏移 */
- (void)keyBoardSelfTextField:(NSNotification *)sender {
    
    /** 键盘高度 */
    CGFloat keyboardH = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    if (keyboardH == 0) return;
    if (self.animation) return;
    
    /** 找不到需要判断的 textField */
    if (self.currentTextField == nil) {
        [self keyBoardHide];
        return;
    }
    
    /** 键盘位置*/
    _keyboardHeight = MAX(keyboardH, _keyboardHeight);
    _keyboardTop = KHeight - _keyboardHeight;
    CGFloat distance = _locationBottom - _keyboardTop;
    
    /** 禁止回滚 or 距离不够*/
    if (distance <= 0) return;
    if (self.rollback == NO && self.scrollView.contentOffset.y >= distance) return;
    
    /** 弹起 */
    if (self.loadFinished) self.animation = YES;
    [UIView animateWithDuration:0.25 animations:^{
        if (self.scrollView) {
            [self.scrollView setContentOffset:CGPointMake(0, distance + self.bottomSpace)];
        } else {
            CGRect rect = self.oldRect;
            rect.origin.y = rect.origin.y - (distance + self.bottomSpace);
            self.underView.frame = rect;
            self.responseView.hidden = NO;
            [self.underView sendSubviewToBack:self.responseView];
        }
    } completion:^(BOOL finished) {
        if (finished) {
            self.animation = NO;
            self.loadFinished = YES;
            self.showKeyboard = YES;
        }
    }];
}

/** 收起键盘 */
- (void)keyBoardWillHide:(NSNotification *)notification {
    self.showKeyboard = NO;
    [self keyBoardHide];
}

- (void)keyBoardHide {
    if (!self.needDisplacement) return;
    if (!self.enabled) return;
    if (self.animation) return;
    self.animation = YES;
    self.responseView.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        if (self.scrollView) [self.scrollView setContentOffset:CGPointZero];
        if (!self.scrollView) self.underView.frame = self.oldRect;
    } completion:^(BOOL finished) {
        if (finished) self.animation = NO;
    }];
}

/** 获取响应的textField */
- (UITextField *)currentTextField {
    _currentTextField = nil;
    __block BOOL currentText = NO;
    
    [self.textFieldArray enumerateObjectsUsingBlock:^(UITextField *obj,NSUInteger idx,BOOL *stop) {
        if (obj.isFirstResponder) self.currentTextField = obj;
        if (currentText == YES) {
            self.nextTextField = obj;
            *stop = YES;
        }
        if (obj.isFirstResponder) currentText = YES;
    }];
    
    return _currentTextField;
}

/** 监听 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (self.showKeyboard == NO && self.referenceType != WXMReferenceNone) return;
    if (self.animation) return;
    if (self.responsing) return;
    
    self.responsing = YES;
    [self.underView endEditing:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.responsing = NO;
    });
}

/** 设置屏幕高度判断  */
- (void)setIgnoreModels:(WXMIgnoreModels)ignoreModels {
    _ignoreModels = ignoreModels;
    CGFloat screenH = 0;
    if (ignoreModels == WXMIgnoreModels_4) screenH = 480;
    if (ignoreModels == WXMIgnoreModels_5) screenH = 568;
    if (ignoreModels == WXMIgnoreModels_8) screenH = 667;
    if (ignoreModels == WXMIgnoreModels_8p) screenH = 763;
    if (ignoreModels == WXMIgnoreModels_x) screenH = 812;
    if (KHeight >= screenH) _needDisplacement = NO;
}

/** 按钮 */
- (void)setNextOptions:(BOOL)nextOptions {
    _nextOptions = nextOptions;
    if (!_nextOptions) return;
    NSInteger count = self.textFieldArray.count - 1;
    [self.textFieldArray enumerateObjectsUsingBlock:^(UITextField *obj,NSUInteger idx,BOOL *stop) {
        obj.returnKeyType = UIReturnKeyNext;
        if (idx == count) obj.returnKeyType = UIReturnKeyDone;
    }];
}

- (void)endRespon {
    [self.underView endEditing:YES];
}

/** GET SET */
- (void)setClickBlack:(BOOL)clickBlack {
    _clickBlack = clickBlack;
    [_responseView removeFromSuperview];
    
    if (self.scrollView) {
        if (clickBlack) {
            [self.scrollView addObserver:self
                              forKeyPath:@"contentOffset"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
        } else {
            @try {
                [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
            } @catch (NSException *exception) {} @finally {};
        }
    } else {
        if (clickBlack) [_underView insertSubview:_responseView atIndex:0];
        if (!clickBlack) [_responseView removeFromSuperview];
    }
}

- (UIControl *)responseView {
    if (!_responseView) {
        _responseView = [[UIControl alloc] initWithFrame:self.underView.bounds];
        _responseView.backgroundColor = [UIColor clearColor];
        [_responseView addTarget:self action:@selector(endRespon)
                forControlEvents:UIControlEventTouchUpInside];
        _responseView.hidden = YES;
    }
    return _responseView;
}

- (void)dealloc {
    _textFieldArray = nil;
    _judgeLocationBottom = nil;
    [KNotificationCenter removeObserver:self];
    
    @try {
        [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    } @catch (NSException *exception) {} @finally {};
}
@end


