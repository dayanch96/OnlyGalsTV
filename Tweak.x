#import "Headers.h"

static BOOL isTweakEnabled = NO;

%hook WEBRTCVideoChatViewController
- (void)updateViewWithAnimation:(BOOL)animated {
    %orig;

    if (!isTweakEnabled) return;

    if (animated) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([self respondsToSelector:@selector(startTranslation)]) {
                [self startTranslation];
            }
        });
    }
}
%end

%hook _TtC5OmeTV18AcceptUserFlatView
- (void)layoutSubviews {
    %orig;

    if (!isTweakEnabled) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([self.avatar.image.description containsString:@"main: male_social"]) {
            id skipBlock = [self skipButtonTapped];
            if (skipBlock) {
                ((void(^)(void))skipBlock)();
            }
        } else {
            id acceptBlock = [self acceptButtonTapped];
            if (acceptBlock) {
                ((void(^)(void))acceptBlock)();
            }
        }
    });
}
%end

%hook _TtC5OmeTV19AreYouThereFlatView
- (void)buttonLabelTimeChange {
    if (isTweakEnabled) {
        [self resetTimer];
    } else {
        %orig;
    }
}

- (void)resetTimer {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        WEBRTCVideoChatViewController *chatVC = (WEBRTCVideoChatViewController *)self._viewControllerForAncestor;
        if ([chatVC respondsToSelector:@selector(startTranslation)]) {
            [chatVC startTranslation];
        }
    });
}
%end

%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        isTweakEnabled = [defaults boolForKey:@"dvn_isTweakEnabled"];
        CGFloat savedX = [defaults floatForKey:@"dvn_floatButtonX"];
        CGFloat savedY = [defaults floatForKey:@"dvn_floatButtonY"];

        UIButton *floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.9 alpha:0.9];
        floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [floatButton setTitle:@"ON" forState:UIControlStateNormal];

        floatButton.frame = CGRectMake(20, 200, 60, 60);
        floatButton.layer.cornerRadius = 30;
        floatButton.layer.masksToBounds = NO;
        floatButton.layer.shadowColor = [UIColor blackColor].CGColor;
        floatButton.layer.shadowOpacity = 0.3;
        floatButton.layer.shadowRadius = 6;
        floatButton.layer.shadowOffset = CGSizeMake(0, 4);
        floatButton.alpha = isTweakEnabled ? 1.0 : 0.4;
        [floatButton setTitle:(isTweakEnabled ? @"ON" : @"OFF") forState:UIControlStateNormal];

        if (savedX > 0 && savedY > 0) {
            floatButton.center = CGPointMake(savedX, savedY);
        }

        [floatButton addTarget:self action:@selector(dvn_toggleTweak:) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dvn_handlePan:)];
        [floatButton addGestureRecognizer:pan];

        UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
        [window addSubview:floatButton];

        objc_setAssociatedObject(window, "DVNFloatButton", floatButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });

    return %orig;
}

%new
- (void)dvn_toggleTweak:(UIButton *)sender {
    isTweakEnabled = !isTweakEnabled;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isTweakEnabled forKey:@"dvn_isTweakEnabled"];
    [defaults synchronize];

    sender.alpha = isTweakEnabled ? 1.0 : 0.4;
    [sender setTitle:(isTweakEnabled ? @"ON" : @"OFF") forState:UIControlStateNormal];
}

%new
- (void)dvn_handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *button = gesture.view;
    UIView *superview = button.superview;
    CGPoint translation = [gesture translationInView:superview];
    button.center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:superview];

    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        CGFloat halfW = button.bounds.size.width / 2.0;
        CGFloat halfH = button.bounds.size.height / 2.0;

        CGFloat newX = MIN(MAX(button.center.x, halfW + 4), screenBounds.size.width - halfW - 4);
        CGFloat newY = MIN(MAX(button.center.y, halfH + 4), screenBounds.size.height - halfH - 4);

        [UIView animateWithDuration:0.2 animations:^{
            button.center = CGPointMake(newX, newY);
        }];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:newX forKey:@"dvn_floatButtonX"];
        [defaults setFloat:newY forKey:@"dvn_floatButtonY"];
        [defaults synchronize];
    }
}
%end
