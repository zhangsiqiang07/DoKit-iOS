//
//  DoraemonNetFlowListViewController.m
//  DoraemonKit
//
//  Created by yixiang on 2018/4/11.
//

#import "DoraemonNetFlowListViewController.h"
#import "DoraemonNetFlowDataSource.h"
#import "DoraemonNetFlowListCell.h"
#import "DoraemonNetFlowHttpModel.h"
#import "DoraemonNetFlowDetailViewController.h"
#import "DoraemonDefine.h"
#import "DoraemonNSLogSearchView.h"

// 声明通知名称（如果头文件中没有导出）
extern NSString * const DoraemonNetFlowDataSourceUpdateNotification;

// 网络请求分类类型
typedef NS_ENUM(NSInteger, DoraemonNetFlowCategoryType) {
    DoraemonNetFlowCategoryTypeAll = 0,        // 全部
    DoraemonNetFlowCategoryTypeAPI = 1,        // 接口请求
    DoraemonNetFlowCategoryTypeResource = 2,  // 资源请求
    DoraemonNetFlowCategoryTypeImage = 3,     // 图片
    DoraemonNetFlowCategoryTypeJS = 4,        // JavaScript
    DoraemonNetFlowCategoryTypeCSS = 5,       // CSS
    DoraemonNetFlowCategoryTypeFont = 6,      // 字体
    DoraemonNetFlowCategoryTypeVideo = 7,     // 视频
    DoraemonNetFlowCategoryTypeAudio = 8      // 音频
};

// 静态变量存储域名过滤列表
static NSMutableArray<NSString *> *sFilterDomains = nil;
static dispatch_once_t sFilterDomainsOnceToken;

@interface DoraemonNetFlowListViewController ()<UITableViewDelegate,UITableViewDataSource,DoraemonNSLogSearchViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *dataArray;
@property (nonatomic, copy) NSArray *allHttpModelArray;
@property (nonatomic, strong) DoraemonNSLogSearchView *searchView;
@property (nonatomic, strong) UISegmentedControl *categorySegmentedControl;
@property (nonatomic, assign) DoraemonNetFlowCategoryType currentCategoryType;
@property (nonatomic, copy) NSString *currentSearchText;

@end

@implementation DoraemonNetFlowListViewController

#pragma mark - Domain Filter Registration
+ (void)registerFilterDomains:(NSArray<NSString *> *)domains {
    dispatch_once(&sFilterDomainsOnceToken, ^{
        sFilterDomains = [NSMutableArray array];
    });
    
    @synchronized(sFilterDomains) {
        [sFilterDomains removeAllObjects];
        if (domains && domains.count > 0) {
            // 转换为小写并去重
            NSMutableSet *domainSet = [NSMutableSet set];
            for (NSString *domain in domains) {
                if (domain && domain.length > 0) {
                    [domainSet addObject:[domain lowercaseString]];
                }
            }
            [sFilterDomains addObjectsFromArray:[domainSet allObjects]];
        }
    }
}

+ (void)clearFilterDomains {
    @synchronized(sFilterDomains) {
        if (sFilterDomains) {
            [sFilterDomains removeAllObjects];
        }
    }
}

+ (NSArray<NSString *> *)filterDomains {
    dispatch_once(&sFilterDomainsOnceToken, ^{
        sFilterDomains = [NSMutableArray array];
    });
    @synchronized(sFilterDomains) {
        return [NSArray arrayWithArray:sFilterDomains];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = DoraemonLocalizedString(@"网络监控列表");
    
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor systemBackgroundColor];
            } else {
                return [UIColor whiteColor];
            }
        }];
    } else {
#endif
        self.view.backgroundColor = [UIColor whiteColor];
#if defined(__IPHONE_13_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0)
    }
#endif
    
    NSArray *dataArray = [DoraemonNetFlowDataSource shareInstance].httpModelArray;
    _dataArray = [NSArray arrayWithArray:dataArray];
    _allHttpModelArray = [NSArray arrayWithArray:dataArray];
    _currentCategoryType = DoraemonNetFlowCategoryTypeAll;
    _currentSearchText = @"";

    // 创建分类分段控制器
    NSArray *categoryItems = @[
        @"全部",
        @"接口",
        @"资源",
        @"图片",
        @"JS",
        @"CSS",
        @"字体",
        @"视频",
        @"音频"
    ];
    _categorySegmentedControl = [[UISegmentedControl alloc] initWithItems:categoryItems];
    _categorySegmentedControl.selectedSegmentIndex = 0;
    _categorySegmentedControl.frame = CGRectMake(kDoraemonSizeFrom750_Landscape(32), IPHONE_NAVIGATIONBAR_HEIGHT+kDoraemonSizeFrom750_Landscape(20), self.view.doraemon_width-2*kDoraemonSizeFrom750_Landscape(32), 32);
    [_categorySegmentedControl addTarget:self action:@selector(categoryChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_categorySegmentedControl];

    _searchView = [[DoraemonNSLogSearchView alloc] initWithFrame:CGRectMake(kDoraemonSizeFrom750_Landscape(32), _categorySegmentedControl.doraemon_bottom+kDoraemonSizeFrom750_Landscape(20), self.view.doraemon_width-2*kDoraemonSizeFrom750_Landscape(32), kDoraemonSizeFrom750_Landscape(100))];
    _searchView.delegate = self;
    [self.view addSubview:_searchView];
    

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _searchView.doraemon_bottom+kDoraemonSizeFrom750_Landscape(30), self.view.doraemon_width, self.view.doraemon_height-_searchView.doraemon_bottom-kDoraemonSizeFrom750_Landscape(30)) style:UITableViewStylePlain];
//    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    // 监听数据源更新通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:DoraemonNetFlowDataSourceUpdateNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 每次显示时刷新数据
    [self refreshData];
}

- (void)refreshData {
    // 重新读取数据源
    NSArray *dataArray = [DoraemonNetFlowDataSource shareInstance].httpModelArray;
    _allHttpModelArray = [NSArray arrayWithArray:dataArray];
    // 重新过滤数据
    [self filterData];
}



#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    DoraemonNetFlowHttpModel* model = [self.dataArray objectAtIndex:indexPath.row];
    return [DoraemonNetFlowListCell cellHeightWithModel:model];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifer = @"httpcell";
    DoraemonNetFlowListCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[DoraemonNetFlowListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
    }
    DoraemonNetFlowHttpModel* model = [self.dataArray objectAtIndex:indexPath.row];
    [cell renderCellWithModel:model];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DoraemonNetFlowHttpModel* model = [self.dataArray objectAtIndex:indexPath.row];
    DoraemonNetFlowDetailViewController *detailVc = [[DoraemonNetFlowDetailViewController alloc] init];
    detailVc.httpModel = model;
    
    [self.navigationController pushViewController:detailVc animated:YES];
}

- (void)leftNavBackClick:(id)clickView{
    [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Category Filter
- (void)categoryChanged:(UISegmentedControl *)sender {
    _currentCategoryType = (DoraemonNetFlowCategoryType)sender.selectedSegmentIndex;
    [self filterData];
}

- (void)filterData {
    NSArray *allHttpModelArray = _allHttpModelArray;
    NSMutableArray *tempArray = [NSMutableArray array];
    
    // 获取域名过滤列表
    NSArray<NSString *> *filterDomains = [[self class] filterDomains];
    
    for (DoraemonNetFlowHttpModel *httpModel in allHttpModelArray) {
        // 先按域名过滤（黑名单模式：过滤掉指定域名的请求）
        if (filterDomains.count > 0) {
            NSString *url = httpModel.url ?: @"";
            NSString *urlLower = [url lowercaseString];
            BOOL shouldFilter = NO;
            
            for (NSString *domain in filterDomains) {
                if ([urlLower containsString:domain]) {
                    shouldFilter = YES;
                    break;
                }
            }
            
            if (shouldFilter) {
                continue;
            }
        }
        
        // 再按分类过滤
        BOOL matchesCategory = [self matchesCategory:httpModel];
        if (!matchesCategory) {
            continue;
        }
        
        // 最后按搜索文本过滤
        if (_currentSearchText.length > 0) {
            NSString *url = httpModel.url ?: @"";
            if (![url containsString:_currentSearchText]) {
                continue;
            }
        }
        
        [tempArray addObject:httpModel];
    }
    
    _dataArray = [NSArray arrayWithArray:tempArray];
    [self.tableView reloadData];
}

- (BOOL)matchesCategory:(DoraemonNetFlowHttpModel *)httpModel {
    if (_currentCategoryType == DoraemonNetFlowCategoryTypeAll) {
        return YES;
    }
    
    NSString *url = httpModel.url ?: @"";
    NSString *mimeType = httpModel.mineType ?: @"";
    NSString *urlLower = [url lowercaseString];
    NSString *mimeTypeLower = [mimeType lowercaseString];
    
    switch (_currentCategoryType) {
        case DoraemonNetFlowCategoryTypeAPI: {
            // 接口请求：通常是 JSON、XML、text/plain，且 URL 不包含静态资源扩展名
            BOOL isResourceExtension = [self isResourceExtension:urlLower];
            BOOL isJSON = [mimeTypeLower containsString:@"json"] || 
                         [mimeTypeLower containsString:@"xml"] ||
                         [mimeTypeLower containsString:@"text/plain"] ||
                         [mimeTypeLower containsString:@"application/"];
            return !isResourceExtension && (isJSON || [self isAPIPath:urlLower]);
        }
        case DoraemonNetFlowCategoryTypeResource: {
            // 资源请求：图片、JS、CSS、字体、视频、音频等
            return [self isResourceRequest:httpModel];
        }
        case DoraemonNetFlowCategoryTypeImage: {
            // 图片
            return [mimeTypeLower hasPrefix:@"image/"] ||
                   [urlLower hasSuffix:@".jpg"] || [urlLower hasSuffix:@".jpeg"] ||
                   [urlLower hasSuffix:@".png"] || [urlLower hasSuffix:@".gif"] ||
                   [urlLower hasSuffix:@".webp"] || [urlLower hasSuffix:@".svg"] ||
                   [urlLower hasSuffix:@".ico"] || [urlLower hasSuffix:@".bmp"];
        }
        case DoraemonNetFlowCategoryTypeJS: {
            // JavaScript
            return [mimeTypeLower containsString:@"javascript"] ||
                   [mimeTypeLower containsString:@"application/javascript"] ||
                   [mimeTypeLower containsString:@"text/javascript"] ||
                   [urlLower hasSuffix:@".js"] || [urlLower containsString:@".js?"];
        }
        case DoraemonNetFlowCategoryTypeCSS: {
            // CSS
            return [mimeTypeLower containsString:@"css"] ||
                   [mimeTypeLower containsString:@"text/css"] ||
                   [urlLower hasSuffix:@".css"] || [urlLower containsString:@".css?"];
        }
        case DoraemonNetFlowCategoryTypeFont: {
            // 字体
            return [mimeTypeLower containsString:@"font"] ||
                   [mimeTypeLower containsString:@"woff"] ||
                   [urlLower hasSuffix:@".woff"] || [urlLower hasSuffix:@".woff2"] ||
                   [urlLower hasSuffix:@".ttf"] || [urlLower hasSuffix:@".otf"] ||
                   [urlLower hasSuffix:@".eot"];
        }
        case DoraemonNetFlowCategoryTypeVideo: {
            // 视频
            return [mimeTypeLower hasPrefix:@"video/"] ||
                   [urlLower hasSuffix:@".mp4"] || [urlLower hasSuffix:@".mov"] ||
                   [urlLower hasSuffix:@".avi"] || [urlLower hasSuffix:@".webm"] ||
                   [urlLower hasSuffix:@".flv"] || [urlLower hasSuffix:@".m3u8"];
        }
        case DoraemonNetFlowCategoryTypeAudio: {
            // 音频
            return [mimeTypeLower hasPrefix:@"audio/"] ||
                   [urlLower hasSuffix:@".mp3"] || [urlLower hasSuffix:@".wav"] ||
                   [urlLower hasSuffix:@".aac"] || [urlLower hasSuffix:@".ogg"] ||
                   [urlLower hasSuffix:@".m4a"];
        }
        default:
            return YES;
    }
}

- (BOOL)isResourceExtension:(NSString *)url {
    NSArray *resourceExtensions = @[@".jpg", @".jpeg", @".png", @".gif", @".webp", @".svg", @".ico", @".bmp",
                                    @".js", @".css", @".woff", @".woff2", @".ttf", @".otf", @".eot",
                                    @".mp4", @".mov", @".avi", @".webm", @".flv", @".m3u8",
                                    @".mp3", @".wav", @".aac", @".ogg", @".m4a",
                                    @".pdf", @".zip", @".rar", @".7z"];
    for (NSString *ext in resourceExtensions) {
        if ([url hasSuffix:ext] || [url containsString:[ext stringByAppendingString:@"?"]]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isResourceRequest:(DoraemonNetFlowHttpModel *)httpModel {
    NSString *url = httpModel.url ?: @"";
    NSString *mimeType = httpModel.mineType ?: @"";
    NSString *urlLower = [url lowercaseString];
    NSString *mimeTypeLower = [mimeType lowercaseString];
    
    // 检查是否是静态资源
    if ([self isResourceExtension:urlLower]) {
        return YES;
    }
    
    // 检查 MIME 类型
    NSArray *resourceMimeTypes = @[@"image/", @"video/", @"audio/", @"font/", @"application/font",
                                    @"text/css", @"application/javascript", @"text/javascript",
                                    @"application/x-font", @"application/x-font-woff"];
    for (NSString *mime in resourceMimeTypes) {
        if ([mimeTypeLower containsString:mime]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isAPIPath:(NSString *)url {
    // 常见的 API 路径模式
    NSArray *apiPatterns = @[@"/api/", @"/v1/", @"/v2/", @"/v3/", @"/rest/", @"/graphql", @"/rpc/"];
    for (NSString *pattern in apiPatterns) {
        if ([url containsString:pattern]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - DoraemonNSLogSearchViewDelegate
- (void)searchViewInputChange:(NSString *)text{
    _currentSearchText = text ?: @"";
    [self filterData];
}

@end
