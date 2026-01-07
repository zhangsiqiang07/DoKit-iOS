//
//  DoraemonNetFlowDetailCell.m
//  DoraemonKit
//
//  Created by yixiang on 2018/4/19.
//

#import "DoraemonNetFlowDetailCell.h"
#import "DoraemonDefine.h"
#import "UIColor+Doraemon.h"
#import "DoraemonSelectableTextView.h"

@interface DoraemonNetFlowDetailCell()<UITextViewDelegate>

@property (nonatomic, strong) UITextView *contentLabel;
@property (nonatomic, strong) UIView *upLine;
@property (nonatomic, strong) UIView *downLine;

@end

@implementation DoraemonNetFlowDetailCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle =  UITableViewCellSelectionStyleNone;
        
        //大文本显示的时候，UIlabel在模拟器上会显示空白，使用TextView代替。
        //网上相似问题： https://blog.csdn.net/minghuyong2016/article/details/82882314
        _contentLabel = [DoraemonNetFlowDetailCell genTextView:16.0];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
        if (@available(iOS 13.0, *)) {
            self.backgroundColor = [UIColor systemBackgroundColor];
            
            _contentLabel.textColor = [UIColor labelColor];
        } else {
#endif
            _contentLabel.textColor = [UIColor blackColor];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
        }
#endif
        _contentLabel.editable = NO;
        _contentLabel.selectable = YES; // 启用文本选择，支持长按全选、复制等功能
        _contentLabel.userInteractionEnabled = YES; // 确保用户交互可用
        _contentLabel.delegate = self; // 设置代理以支持菜单功能
        // 确保 UITextView 不会拦截 UITableView 的滚动事件
        // 当 scrollEnabled = NO 时，UITextView 会自动让滚动事件传递给 UITableView
        [self.contentView addSubview:_contentLabel];
        
        // 确保 Cell 可以响应菜单操作
        self.userInteractionEnabled = YES;
        
        _upLine = [[UIView alloc] init];
        _upLine.backgroundColor = [UIColor doraemon_colorWithHex:0xF2F2F2];
        [self.contentView addSubview:_upLine];
        _upLine.hidden = YES;
        
        _downLine = [[UIView alloc] init];
        _downLine.backgroundColor = [UIColor doraemon_colorWithHex:0xF2F2F2];
        [self.contentView addSubview:_downLine];
        _downLine.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 确保 frame 正确，避免内容被截断
    CGFloat cellWidth = DoraemonScreenWidth - kDoraemonSizeFrom750_Landscape(32) * 2;
    if (self->_contentLabel.frame.size.width != cellWidth) {
        CGRect frame = self->_contentLabel.frame;
        frame.size.width = cellWidth;
        self->_contentLabel.frame = frame;
    }
}

- (void)renderUIWithContent:(NSString *)content isFirst:(BOOL)isFirst isLast:(BOOL)isLast{
    CGFloat cellWidth = DoraemonScreenWidth - kDoraemonSizeFrom750_Landscape(32) * 2;
    
    // 使用 performWithoutAnimation 减少动画开销
    [UIView performWithoutAnimation:^{
        self->_contentLabel.text = content;
        
        // 计算高度（始终禁用滚动，避免与 UITableView 冲突）
        self->_contentLabel.scrollEnabled = NO;
        CGSize fontSize = [self->_contentLabel sizeThatFits:CGSizeMake(cellWidth, MAXFLOAT)];
        self->_contentLabel.frame = CGRectMake(kDoraemonSizeFrom750_Landscape(32), kDoraemonSizeFrom750_Landscape(28), cellWidth, fontSize.height);
        
        CGFloat cellHeight = fontSize.height + kDoraemonSizeFrom750_Landscape(28) * 2;
        
        // 更新分割线
        if(isFirst && isLast){
            self->_upLine.hidden = NO;
            self->_upLine.frame = CGRectMake(0, 0, DoraemonScreenWidth, 0.5);
            self->_downLine.hidden = NO;
            self->_downLine.frame = CGRectMake(0, cellHeight-0.5, DoraemonScreenWidth, 0.5);
        }else if(isFirst && !isLast){
            self->_upLine.hidden = NO;
            self->_upLine.frame = CGRectMake(0, 0, DoraemonScreenWidth, 0.5);
            self->_downLine.hidden = NO;
            self->_downLine.frame = CGRectMake(20, cellHeight-0.5, DoraemonScreenWidth-20, 0.5);
        }else if(!isFirst && isLast){
            self->_upLine.hidden = YES;
            self->_downLine.hidden = NO;
            self->_downLine.frame = CGRectMake(0, cellHeight-0.5, DoraemonScreenWidth, 0.5);
        }else{
            self->_upLine.hidden = YES;
            self->_downLine.hidden = NO;
            self->_downLine.frame = CGRectMake(20, cellHeight-0.5, DoraemonScreenWidth-20, 0.5);
        }
    }];
}

+ (CGFloat)cellHeightWithContent:(NSString *)content{
    // 对于超大文本，使用快速估算避免创建完整的 UITextView
    if (content.length > 50000) {
        // 使用简单的行数估算
        CGFloat estimatedLineHeight = 20.0; // 大约的行高
        NSInteger lineCount = (NSInteger)(content.length / 50.0); // 粗略估算行数
        CGFloat estimatedHeight = lineCount * estimatedLineHeight;
        return estimatedHeight + kDoraemonSizeFrom750_Landscape(28) * 2;
    }
    
    UITextView *tempLabel = [DoraemonNetFlowDetailCell genTextView:16.0];
    tempLabel.text = content;
    CGSize fontSize = [tempLabel sizeThatFits:CGSizeMake(DoraemonScreenWidth-2*kDoraemonSizeFrom750_Landscape(32), MAXFLOAT)];
    
    return fontSize.height + kDoraemonSizeFrom750_Landscape(28) * 2;
}

/// 生成 UITextView
+ (UITextView *)genTextView:(CGFloat)fontSize {
    UITextView *tempTextView = [[DoraemonSelectableTextView alloc] init];
    tempTextView.font = [UIFont systemFontOfSize:fontSize];
    // 性能优化：禁用不必要的特性
    tempTextView.textContainerInset = UIEdgeInsetsZero;
    tempTextView.textContainer.lineFragmentPadding = 0;
    tempTextView.layoutManager.allowsNonContiguousLayout = YES; // 允许非连续布局，提升大文本性能
    tempTextView.textContainer.maximumNumberOfLines = 0;
    tempTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    // 启用文本选择功能，支持长按全选、复制等系统功能
    tempTextView.editable = NO;
    tempTextView.selectable = YES;
    tempTextView.userInteractionEnabled = YES;
    return tempTextView;
}

#pragma mark - UITextViewDelegate
// 确保菜单可以显示
- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return YES;
}

// 当 UITextView 选择文本时，确保菜单可以显示
- (void)textViewDidChangeSelection:(UITextView *)textView {
    // 如果是 DoraemonSelectableTextView，调用其菜单显示方法
    if ([textView isKindOfClass:[DoraemonSelectableTextView class]]) {
        DoraemonSelectableTextView *selectableTextView = (DoraemonSelectableTextView *)textView;
        [selectableTextView showMenuIfNeeded];
    } else {
        // 其他情况，确保 UITextView 可以成为第一响应者
        if (textView.selectedRange.length > 0 && ![textView isFirstResponder]) {
            [textView becomeFirstResponder];
        }
    }
}

@end
