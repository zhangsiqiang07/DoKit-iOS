//
//  DoraemonStartTimeProfilerViewController.m
//  DoraemonKit
//
//  Created by didi on 2020/4/13.
//

#import "DoraemonStartTimeProfilerViewController.h"
#import "DoraemonDefine.h"

#if DoraemonWithDiDi
#import "DoraemonHealthManager.h"
#endif

@interface DoraemonStartTimeProfilerViewController ()

@property (nonatomic, strong) UITextView *contentLabel;

@end

@implementation DoraemonStartTimeProfilerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = DoraemonLocalizedString(@"启动耗时");
    [self setRightNavTitle:DoraemonLocalizedString(@"导出")];
    
    _contentLabel = [[UITextView alloc] initWithFrame:self.view.bounds];
    _contentLabel.textColor = [UIColor doraemon_black_2];
    _contentLabel.font = [UIFont systemFontOfSize:kDoraemonSizeFrom750_Landscape(16)];
#if DoraemonWithDiDi
    NSString *costDetail = [DoraemonHealthManager sharedInstance].costDetail;
    _contentLabel.text = costDetail;
#endif
    
    [self.view addSubview:_contentLabel];
}

- (void)rightNavTitleClick:(id)clickView {
    [DoraemonUtil shareText:_contentLabel.text formVC:self];
}

@end
