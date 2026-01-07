//
//  DoraemonTextMenuView.h
//  DoraemonKit
//
//  Created for custom text menu
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DoraemonTextMenuView;

@protocol DoraemonTextMenuViewDelegate <NSObject>
- (void)textMenuViewDidSelectCopy:(DoraemonTextMenuView *)menuView;
- (void)textMenuViewDidSelectSelectAll:(DoraemonTextMenuView *)menuView;
@end

@interface DoraemonTextMenuView : UIView

@property (nonatomic, weak) id<DoraemonTextMenuViewDelegate> delegate;

+ (instancetype)showMenuAtPoint:(CGPoint)point inView:(UIView *)view delegate:(id<DoraemonTextMenuViewDelegate>)delegate;
- (void)hide;

@end

NS_ASSUME_NONNULL_END

