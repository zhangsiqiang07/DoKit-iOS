//
//  DoraemonTextMenuView.m
//  DoraemonKit
//
//  Created for custom text menu
//

#import "DoraemonTextMenuView.h"
#import "DoraemonDefine.h"
#import <objc/runtime.h>

@interface DoraemonTextMenuView ()

@property (nonatomic, strong) UIButton *menuCopyButton;
@property (nonatomic, strong) UIButton *selectAllButton;
@property (nonatomic, strong) UIView *containerView;

@end

@implementation DoraemonTextMenuView

+ (instancetype)showMenuAtPoint:(CGPoint)point inView:(UIView *)view delegate:(id<DoraemonTextMenuViewDelegate>)delegate {
    // 先隐藏已存在的菜单
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[DoraemonTextMenuView class]]) {
            [(DoraemonTextMenuView *)subview hide];
        }
    }
    
    // 设置菜单位置
    CGFloat menuWidth = 140;
    CGFloat menuHeight = 88;
    CGFloat padding = 8;
    
    // 确保菜单不超出屏幕
    CGFloat x = point.x - menuWidth / 2;
    CGFloat y = point.y - menuHeight - 10;
    
    if (x < padding) {
        x = padding;
    } else if (x + menuWidth > view.bounds.size.width - padding) {
        x = view.bounds.size.width - menuWidth - padding;
    }
    
    if (y < padding) {
        y = point.y + 10;
    }
    
    // 使用确定的 frame 初始化
    CGRect menuFrame = CGRectMake(x, y, menuWidth, menuHeight);
    DoraemonTextMenuView *menuView = [[DoraemonTextMenuView alloc] initWithFrame:menuFrame];
    menuView.delegate = delegate;
    [view addSubview:menuView];
    
    // 强制布局更新
    [menuView setNeedsLayout];
    [menuView layoutIfNeeded];
    
    menuView.alpha = 0;
    
    // 添加点击外部隐藏的手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:menuView action:@selector(handleTapOutside:)];
    tapGesture.cancelsTouchesInView = NO;
    [view addGestureRecognizer:tapGesture];
    objc_setAssociatedObject(menuView, @selector(handleTapOutside:), tapGesture, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [UIView animateWithDuration:0.2 animations:^{
        menuView.alpha = 1;
    }];
    
    return menuView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self layoutSubviews];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    
    // 容器视图
    _containerView = [[UIView alloc] init];
    _containerView.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1.0]; // 完全不透明
    _containerView.layer.cornerRadius = 8;
    _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _containerView.layer.shadowOffset = CGSizeMake(0, 2);
    _containerView.layer.shadowOpacity = 0.3;
    _containerView.layer.shadowRadius = 4;
    _containerView.layer.masksToBounds = NO;
    [self addSubview:_containerView];
    
    // 复制按钮
    _menuCopyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_menuCopyButton setTitle:@"复制" forState:UIControlStateNormal];
    [_menuCopyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _menuCopyButton.titleLabel.font = [UIFont systemFontOfSize:16];
    _menuCopyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _menuCopyButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
    [_menuCopyButton addTarget:self action:@selector(copyButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_menuCopyButton];
    
    // 分割线
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    separator.tag = 999; // 使用 tag 标识分割线
    [_containerView addSubview:separator];
    
    // 全选按钮
    _selectAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_selectAllButton setTitle:@"全选并复制" forState:UIControlStateNormal];
    [_selectAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _selectAllButton.titleLabel.font = [UIFont systemFontOfSize:16];
    _selectAllButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _selectAllButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
    [_selectAllButton addTarget:self action:@selector(selectAllButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:_selectAllButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 确保 frame 有效
    CGRect bounds = self.bounds;
    if (bounds.size.width > 0 && bounds.size.height > 0) {
        // 容器视图填充整个 bounds
        _containerView.frame = bounds;
        
        // 复制按钮
        _menuCopyButton.frame = CGRectMake(0, 0, bounds.size.width, 44);
        
        // 分割线
        UIView *separator = [_containerView viewWithTag:999];
        if (separator) {
            separator.frame = CGRectMake(0, 44, bounds.size.width, 0.5);
        }
        
        // 全选按钮
        _selectAllButton.frame = CGRectMake(0, 44.5, bounds.size.width, 44);
    }
}

- (void)copyButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(textMenuViewDidSelectCopy:)]) {
        [self.delegate textMenuViewDidSelectCopy:self];
    }
    [self hide];
}

- (void)selectAllButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(textMenuViewDidSelectSelectAll:)]) {
        [self.delegate textMenuViewDidSelectSelectAll:self];
    }
    [self hide];
}

- (void)handleTapOutside:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.superview];
    if (!CGRectContainsPoint(self.frame, location)) {
        [self hide];
        // 移除手势识别器
        UITapGestureRecognizer *tapGesture = objc_getAssociatedObject(self, @selector(handleTapOutside:));
        if (tapGesture) {
            [self.superview removeGestureRecognizer:tapGesture];
        }
    }
}

- (void)hide {
    // 移除手势识别器
    UITapGestureRecognizer *tapGesture = objc_getAssociatedObject(self, @selector(handleTapOutside:));
    if (tapGesture && self.superview) {
        [self.superview removeGestureRecognizer:tapGesture];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
