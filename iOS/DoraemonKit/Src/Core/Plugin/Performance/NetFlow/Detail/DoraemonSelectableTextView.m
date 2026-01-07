//
//  DoraemonSelectableTextView.m
//  DoraemonKit
//
//  Created for menu support
//

#import "DoraemonSelectableTextView.h"
#import "DoraemonTextMenuView.h"

@interface DoraemonSelectableTextView () <DoraemonTextMenuViewDelegate>
@property (nonatomic, strong) DoraemonTextMenuView *menuView;
@end

@implementation DoraemonSelectableTextView

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    // 禁用系统菜单，使用自定义菜单
    return NO;
}

- (void)copy:(id)sender {
    if (self.selectedRange.length > 0) {
        NSString *selectedText = [self.text substringWithRange:self.selectedRange];
        UIPasteboard *pboard = [UIPasteboard generalPasteboard];
        pboard.string = selectedText;
    }
}

- (void)selectAll:(id)sender {
    if (self.text.length > 0) {
        self.selectedRange = NSMakeRange(0, self.text.length);
    }
}

// 公开方法，供外部调用显示菜单
- (void)showMenuIfNeeded {
    if (self.selectedRange.length == 0) {
        return;
    }
    
    // 隐藏之前的菜单
    if (self.menuView) {
        [self.menuView hide];
        self.menuView = nil;
    }
    
    // 确保是第一响应者
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    }
    
    // 延迟一下，确保选择状态已经更新
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.selectedRange.length > 0) {
            [self showCustomMenu];
        }
    });
}

- (void)showCustomMenu {
    if (self.selectedRange.length == 0) {
        return;
    }
    
    // 获取选中文本的位置
    UITextRange *selectedRange = [self selectedTextRange];
    if (!selectedRange) {
        return;
    }
    
    CGRect selectionRect = [self firstRectForRange:selectedRange];
    
    // 找到控制器
    UIResponder *responder = self;
    while (responder && ![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
    }
    
    UIViewController *viewController = (UIViewController *)responder;
    if (!viewController || !viewController.view) {
        return;
    }
    
    // 计算菜单显示位置（选中文本的中心点上方）
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(selectionRect), CGRectGetMinY(selectionRect));
    CGPoint pointInControllerView = [self convertPoint:centerPoint toView:viewController.view];
    
    // 显示菜单
    self.menuView = [DoraemonTextMenuView showMenuAtPoint:pointInControllerView inView:viewController.view delegate:self];
}

- (void)hideMenu {
    if (self.menuView) {
        [self.menuView hide];
        self.menuView = nil;
    }
}

#pragma mark - DoraemonTextMenuViewDelegate
- (void)textMenuViewDidSelectCopy:(DoraemonTextMenuView *)menuView {
    [self copy:nil];
}

- (void)textMenuViewDidSelectSelectAll:(DoraemonTextMenuView *)menuView {
    [self selectAll:nil];
    // 全选后自动复制
    [self copy:nil];
}

- (void)dealloc {
    [self hideMenu];
}

@end
