//
//  DoraemonNetFlowDetailViewController.m
//  DoraemonKit
//
//  Created by yixiang on 2018/4/13.
//

#import "DoraemonNetFlowDetailViewController.h"
#import "UIView+Doraemon.h"
#import "DoraemonNetFlowDetailCell.h"
#import "UIColor+Doraemon.h"
#import "DoraemonUrlUtil.h"
#import "DoraemonUtil.h"
#import "DoraemonDefine.h"
#import "DoraemonNetFlowDetailSegment.h"
#import "DoraemonSelectableTextView.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, NetFlowSelectState) {
    NetFlowSelectStateForRequest = 0,
    NetFlowSelectStateForResponse
};

@interface DoraemonNetFlowDetailViewController ()<UITableViewDelegate,UITableViewDataSource,DoraemonNetFlowDetailSegmentDelegate,UITextViewDelegate>

@property (nonatomic, strong) DoraemonNetFlowDetailSegment *segmentView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;//当前选中的tab

@property (nonatomic, copy) NSArray* requestArray;
@property (nonatomic, copy) NSArray* responseArray;

@property (nonatomic, strong) NSMutableDictionary *fullContentDict; // 存储完整内容
@property (nonatomic, assign) NSInteger maxDisplayLength; // 最大显示长度，默认 5000

@end

@implementation DoraemonNetFlowDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor systemBackgroundColor];
            } else {
                return [UIColor doraemon_colorWithHex:0xeff0f4];
            }
        }];
    } else {
#endif
        self.view.backgroundColor = [UIColor doraemon_colorWithHex:0xeff0f4];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    }
#endif
    
    [self initData];
    
    self.title = DoraemonLocalizedString(@"网络监控详情");
    
    _segmentView = [[DoraemonNetFlowDetailSegment alloc] initWithFrame:CGRectMake(0, IPHONE_NAVIGATIONBAR_HEIGHT, self.view.doraemon_width, kDoraemonSizeFrom750_Landscape(88))];
    _segmentView.delegate = self;
    [self.view addSubview:_segmentView];
    
    CGFloat tabBarHeight = self.tabBarController.tabBar.doraemon_height;
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _segmentView.doraemon_bottom, self.view.doraemon_width, self.view.doraemon_height-tabBarHeight-_segmentView.doraemon_bottom) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.estimatedRowHeight = 0.;
    _tableView.estimatedSectionFooterHeight = 0.;
    _tableView.estimatedSectionHeaderHeight = 0.;
    // 确保 UITableView 可以正常滚动，同时支持 UITextView 的文本选择
    _tableView.canCancelContentTouches = YES;
    _tableView.delaysContentTouches = YES; // 延迟内容触摸，确保 UITableView 可以正常滚动
    // 允许 UITextView 在 Cell 中显示菜单
    _tableView.allowsSelection = NO; // 禁用 cell 选择，避免干扰文本选择
    [self.view addSubview:_tableView];
}

- (void)initData{
    
    NSString *requestDataSize = [NSString stringWithFormat:DoraemonLocalizedString(@"数据大小 : %@"),[DoraemonUtil formatByte:[self.httpModel.uploadFlow floatValue]]];
    NSString *method = [NSString stringWithFormat:@"Method : %@",self.httpModel.method];
    NSString *linkUrl = self.httpModel.url;
    NSDictionary<NSString *, NSString *> *allHTTPHeaderFields = self.httpModel.request.allHTTPHeaderFields;
    NSMutableString *allHTTPHeaderString = [NSMutableString string];
    for (NSString *key in allHTTPHeaderFields) {
        NSString *value = allHTTPHeaderFields[key];
        [allHTTPHeaderString appendFormat:@"%@ : %@\r\n",key,value];
    }
    if (allHTTPHeaderString.length == 0) {
        allHTTPHeaderString = [NSMutableString stringWithFormat:@"NULL"];
    }
    
    NSString *requestBody = self.httpModel.requestBody;
    if (!requestBody || requestBody.length == 0) {
        requestBody = @"NULL";
    }
    
    // 初始化内容字典
    _fullContentDict = [NSMutableDictionary dictionary];
    _maxDisplayLength = 5000; // 默认显示前 5000 个字符
    
    // 存储完整内容
    NSString *requestBodyKey = @"requestBody";
    _fullContentDict[requestBodyKey] = requestBody;
    NSString *truncatedRequestBody = [self truncateText:requestBody];
    
    _requestArray = @[@{
                          @"sectionTitle":DoraemonLocalizedString(@"请求概要"),
                          @"dataArray":@[requestDataSize,method]
                          },
                      @{
                          @"sectionTitle":DoraemonLocalizedString(@"链接"),
                          @"dataArray":@[linkUrl]
                          },
                      @{
                          @"sectionTitle":DoraemonLocalizedString(@"请求头"),
                          @"dataArray":@[allHTTPHeaderString]
                          },
                      @{
                          @"sectionTitle":DoraemonLocalizedString(@"请求体"),
                          @"dataArray":@[truncatedRequestBody],
                          @"isExpandable":@(requestBody.length > _maxDisplayLength),
                          @"contentKey":requestBodyKey
                          }
                      ];
    
    NSString *respanseDataSize = [NSString stringWithFormat:DoraemonLocalizedString(@"数据大小 : %@"),[DoraemonUtil formatByte:[self.httpModel.downFlow floatValue]]];
    NSString *mineType = [NSString stringWithFormat:@"mineType : %@",self.httpModel.mineType];
    NSMutableString *responseHeaderString = [NSMutableString string];
    for (NSString *key in allHTTPHeaderFields) {
        NSString *value = allHTTPHeaderFields[key];
        [responseHeaderString appendFormat:@"%@ : %@\r\n",key,value];
    }
    if (responseHeaderString.length == 0) {
        responseHeaderString = [NSMutableString stringWithFormat:@"NULL"];
    }
    NSString *responseBody = self.httpModel.responseBody;
    if (!responseBody || responseBody.length == 0) {
        responseBody = @"NULL";
    }
    
    // 处理响应体
    NSString *responseBodyKey = @"responseBody";
    _fullContentDict[responseBodyKey] = responseBody;
    NSString *truncatedResponseBody = [self truncateText:responseBody];
    
    _responseArray = @[@{
                          @"sectionTitle":DoraemonLocalizedString(@"响应概要"),
                          @"dataArray":@[respanseDataSize,mineType]
                          },
                      @{
                          @"sectionTitle":DoraemonLocalizedString(@"响应头"),
                          @"dataArray":@[responseHeaderString]
                          },
                      @{
                          @"sectionTitle":DoraemonLocalizedString(@"响应体"),
                          @"dataArray":@[truncatedResponseBody],
                          @"isExpandable":@(responseBody.length > _maxDisplayLength),
                          @"contentKey":responseBodyKey
                          }
                      ];
    
    _selectedSegmentIndex = NetFlowSelectStateForRequest;
}

- (NSString *)truncateText:(NSString *)text {
    if (!text || text.length <= _maxDisplayLength) {
        return text;
    }
    NSString *truncated = [text substringToIndex:_maxDisplayLength];
    return [NSString stringWithFormat:@"%@\n\n... [内容过长，已截断，点击查看完整内容] ...", truncated];
}

#pragma mark - DoraemonNetFlowDetailSegmentDelegate
- (void)segmentClick:(NSInteger)index{
    _selectedSegmentIndex = index;
    [_tableView reloadData];
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger section=0;
    if (_selectedSegmentIndex == NetFlowSelectStateForRequest) {
        section = 4;
    }else{
        section = 3;
    }
    return section;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger row = 0;
    if (_selectedSegmentIndex == NetFlowSelectStateForRequest) {
        if(section == 0){
            row = 2;
        }else if(section == 1){
            row = 1;
        }else if(section == 2){
            row = 1;
        }else{
            row = 1;
        }
    }else{
        if(section == 0){
            row = 2;
        }else if(section == 1){
            row = 1;
        }else{
            row = 1;
        }
    }
    
    return row;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *content;
    
    if (_selectedSegmentIndex == NetFlowSelectStateForRequest) {
        NSDictionary *itemInfo = _requestArray[indexPath.section];
        content = itemInfo[@"dataArray"][indexPath.row];
    }else{
        NSDictionary *itemInfo = _responseArray[indexPath.section];
        content = itemInfo[@"dataArray"][indexPath.row];
    }
    
    // 始终使用截断后的内容计算高度，避免大文本卡顿
    return [DoraemonNetFlowDetailCell cellHeightWithContent:content];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kDoraemonSizeFrom750_Landscape(100);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *title;
    if (_selectedSegmentIndex == NetFlowSelectStateForRequest) {
        NSDictionary *itemInfo = _requestArray[section];
        title = itemInfo[@"sectionTitle"];
    }else{
        NSDictionary *itemInfo = _responseArray[section];
        title = itemInfo[@"sectionTitle"];
    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.doraemon_width, kDoraemonSizeFrom750_Landscape(100))];
    
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.textColor = [UIColor doraemon_colorWithHex:0x337CC4];
    tipLabel.font = [UIFont systemFontOfSize:kDoraemonSizeFrom750_Landscape(32)];
    tipLabel.text = title;
    tipLabel.frame = CGRectMake(kDoraemonSizeFrom750_Landscape(32), 0, self.view.doraemon_width-kDoraemonSizeFrom750_Landscape(32), kDoraemonSizeFrom750_Landscape(100));
    [view addSubview:tipLabel];
    //tipLabel.backgroundColor = [UIColor doraemon_colorWithHex:0xeff0f4];
    
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    if (@available(iOS 13.0, *)) {
        view.backgroundColor =  [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor systemBackgroundColor];
            } else {
                return [UIColor whiteColor];
            }
        }];
    }
#endif
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"httpcell";
    DoraemonNetFlowDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[DoraemonNetFlowDetailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
    }
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    NSString *content;
    BOOL isExpandable = NO;
    NSString *contentKey = nil;
    
    if (_selectedSegmentIndex == NetFlowSelectStateForRequest) {
        NSDictionary *itemInfo = _requestArray[section];
        content = itemInfo[@"dataArray"][row];
        isExpandable = [itemInfo[@"isExpandable"] boolValue];
        contentKey = itemInfo[@"contentKey"];
    }else{
        NSDictionary *itemInfo = _responseArray[section];
        content = itemInfo[@"dataArray"][row];
        isExpandable = [itemInfo[@"isExpandable"] boolValue];
        contentKey = itemInfo[@"contentKey"];
    }
    
    // 始终使用截断后的内容显示，避免大文本卡顿
    if (section == 0) {
        if (row==0) {
            [cell renderUIWithContent:content isFirst:YES isLast:NO];
        }else if(row==1){
            [cell renderUIWithContent:content isFirst:NO isLast:YES];
        }
    }else if(section == 1){
        [cell renderUIWithContent:content isFirst:YES isLast:YES];
    }else if(section == 2){
        [cell renderUIWithContent:content isFirst:YES isLast:YES];
    }else if(section == 3){
        [cell renderUIWithContent:content isFirst:YES isLast:YES];
    }
    
    // 如果是可展开的内容，添加点击手势跳转到详情页面
    if (isExpandable && contentKey) {
        // 清除之前的 gesture recognizers
        for (UIGestureRecognizer *gesture in cell.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                [cell removeGestureRecognizer:gesture];
            }
        }
        
        // 检查点击位置是否在截断提示区域
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullContent:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.cancelsTouchesInView = NO; // 不取消视图中的触摸，允许 UITableView 滚动和文本选择
        [cell addGestureRecognizer:tapGesture];
        objc_setAssociatedObject(cell, @"contentKey", contentKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return cell;
}

- (void)showFullContent:(UITapGestureRecognizer *)gesture {
    UITableViewCell *cell = (UITableViewCell *)gesture.view;
    NSString *contentKey = objc_getAssociatedObject(cell, @"contentKey");
    
    if (contentKey && _fullContentDict[contentKey]) {
        NSString *fullContent = _fullContentDict[contentKey];
        NSString *title = nil;
        
        // 根据 contentKey 确定标题
        if ([contentKey isEqualToString:@"requestBody"]) {
            title = DoraemonLocalizedString(@"请求体");
        } else if ([contentKey isEqualToString:@"responseBody"]) {
            title = DoraemonLocalizedString(@"响应体");
        }
        
        // 创建全屏显示页面
        UIViewController *fullContentVC = [[UIViewController alloc] init];
        fullContentVC.title = title ?: DoraemonLocalizedString(@"完整内容");
        fullContentVC.view.backgroundColor = [UIColor whiteColor];
        
        // 使用 DoraemonSelectableTextView 以支持自定义菜单
        DoraemonSelectableTextView *textView = [[DoraemonSelectableTextView alloc] init];
        textView.text = fullContent;
        textView.font = [UIFont systemFontOfSize:16];
        textView.editable = NO;
        textView.selectable = YES;
        textView.textContainerInset = UIEdgeInsetsMake(20, 16, 20, 16);
        textView.translatesAutoresizingMaskIntoConstraints = NO;
        // 设置 delegate 以监听选择变化并显示菜单
        textView.delegate = self;
        [fullContentVC.view addSubview:textView];
        
        [NSLayoutConstraint activateConstraints:@[
            [textView.topAnchor constraintEqualToAnchor:fullContentVC.view.safeAreaLayoutGuide.topAnchor],
            [textView.leadingAnchor constraintEqualToAnchor:fullContentVC.view.leadingAnchor],
            [textView.trailingAnchor constraintEqualToAnchor:fullContentVC.view.trailingAnchor],
            [textView.bottomAnchor constraintEqualToAnchor:fullContentVC.view.bottomAnchor]
        ]];
        
        // 添加关闭按钮
        UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissFullContent:)];
        fullContentVC.navigationItem.rightBarButtonItem = closeItem;
        
        // 使用导航控制器推送
        if (self.navigationController) {
            [self.navigationController pushViewController:fullContentVC animated:YES];
        } else {
            // 如果没有导航控制器，使用模态展示
            UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:fullContentVC];
            [self presentViewController:navVC animated:YES completion:nil];
        }
    }
}

- (void)dismissFullContent:(id)sender {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChangeSelection:(UITextView *)textView {
    // 如果是 DoraemonSelectableTextView，调用其菜单显示方法
    if ([textView isKindOfClass:[DoraemonSelectableTextView class]]) {
        DoraemonSelectableTextView *selectableTextView = (DoraemonSelectableTextView *)textView;
        [selectableTextView showMenuIfNeeded];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return DoraemonLocalizedString(@"复制");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    NSString *content;
    NSString *contentKey = nil;
    if (_selectedSegmentIndex == NetFlowSelectStateForRequest) {
        NSDictionary *itemInfo = _requestArray[section];
        content = itemInfo[@"dataArray"][row];
        contentKey = itemInfo[@"contentKey"];
    }else{
        NSDictionary *itemInfo = _responseArray[section];
        content = itemInfo[@"dataArray"][row];
        contentKey = itemInfo[@"contentKey"];
    }
    
    // 如果有完整内容，复制完整内容
    if (contentKey && _fullContentDict[contentKey]) {
        content = _fullContentDict[contentKey];
    }
    
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    pboard.string = content;
}
@end
