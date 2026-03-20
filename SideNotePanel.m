#import "SideNotePanel.h"
#import "SideNotePassthroughView.h"
#import "SideNotePassthroughWindow.h"
#import "SideNoteStorage.h"

static const CGFloat kTabWidth = 20.0;
static const CGFloat kTabHeight = 44.0;
static const CGFloat kPanelWidth = 300.0;
static const CGFloat kPanelHeight = 400.0;

@interface SideNotePanel () <UITextViewDelegate>

@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) UIView *tabView;
@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL panelOpen;
@property (nonatomic, assign) CGFloat tabCenterY;

@end

@implementation SideNotePanel

+ (instancetype)sharedInstance {
    static SideNotePanel *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SideNotePanel alloc] init];
    });
    return instance;
}

- (void)setup {
    [self createOverlayWindow];
    [self createTab];
    [self createPanel];
    [self registerKeyboardNotifications];
}

#pragma mark - Overlay Window

- (void)createOverlayWindow {
    self.overlayWindow = [[SideNotePassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.overlayWindow.windowLevel = 1999;
    self.overlayWindow.backgroundColor = [UIColor clearColor];
    self.overlayWindow.hidden = NO;

    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view = [[SideNotePassthroughView alloc] initWithFrame:self.overlayWindow.bounds];
    rootVC.view.backgroundColor = [UIColor clearColor];
    self.overlayWindow.rootViewController = rootVC;
}

#pragma mark - Tab

- (void)createTab {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.tabCenterY = screenBounds.size.height / 2.0;

    self.tabView = [[UIView alloc] initWithFrame:CGRectMake(
        screenBounds.size.width - kTabWidth,
        self.tabCenterY - kTabHeight / 2.0,
        kTabWidth,
        kTabHeight
    )];
    self.tabView.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:0.7];
    self.tabView.layer.cornerRadius = 10.0;
    self.tabView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    self.tabView.userInteractionEnabled = YES;

    UILabel *tabLabel = [[UILabel alloc] initWithFrame:self.tabView.bounds];
    tabLabel.text = @"📝";
    tabLabel.textAlignment = NSTextAlignmentCenter;
    tabLabel.font = [UIFont systemFontOfSize:14];
    [self.tabView addSubview:tabLabel];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabTapped:)];
    [self.tabView addGestureRecognizer:tap];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(tabDragged:)];
    [self.tabView addGestureRecognizer:pan];

    [self.overlayWindow.rootViewController.view addSubview:self.tabView];
}

- (void)tabTapped:(UITapGestureRecognizer *)gesture {
    if (self.panelOpen) {
        [self closePanel];
    } else {
        [self openPanel];
    }
}

- (void)tabDragged:(UIPanGestureRecognizer *)gesture {
    if (self.panelOpen) return;

    CGPoint translation = [gesture translationInView:self.overlayWindow.rootViewController.view];
    CGFloat newCenterY = self.tabCenterY + translation.y;

    UIEdgeInsets safeInsets = self.overlayWindow.safeAreaInsets;
    CGFloat minY = safeInsets.top + kTabHeight / 2.0;
    CGFloat maxY = [UIScreen mainScreen].bounds.size.height - safeInsets.bottom - kTabHeight / 2.0;
    newCenterY = MAX(minY, MIN(maxY, newCenterY));

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect frame = self.tabView.frame;
        frame.origin.y = newCenterY - kTabHeight / 2.0;
        self.tabView.frame = frame;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        self.tabCenterY = newCenterY;
    }
}

#pragma mark - Panel

- (void)createPanel {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    UIEdgeInsets safeInsets = self.overlayWindow.safeAreaInsets;

    self.panelView = [[UIView alloc] initWithFrame:CGRectMake(
        screenBounds.size.width,
        safeInsets.top + 40,
        kPanelWidth,
        kPanelHeight
    )];
    self.panelView.backgroundColor = [UIColor systemBackgroundColor];
    self.panelView.layer.cornerRadius = 16.0;
    self.panelView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.panelView.layer.shadowOpacity = 0.3;
    self.panelView.layer.shadowOffset = CGSizeMake(-2, 2);
    self.panelView.layer.shadowRadius = 10.0;
    self.panelView.clipsToBounds = NO;

    // Title bar
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kPanelWidth, 44)];
    titleBar.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0];
    titleBar.layer.cornerRadius = 16.0;
    titleBar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 200, 44)];
    titleLabel.text = @"SideNote";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [titleBar addSubview:titleLabel];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(kPanelWidth - 50, 0, 44, 44);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    [closeBtn addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];

    [self.panelView addSubview:titleBar];

    // Text view
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(8, 52, kPanelWidth - 16, kPanelHeight - 60)];
    self.textView.font = [UIFont systemFontOfSize:15];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.delegate = self;
    [self.panelView addSubview:self.textView];

    [self.overlayWindow.rootViewController.view addSubview:self.panelView];
}

#pragma mark - Open / Close

- (void)openPanel {
    if (self.panelOpen) return;
    self.panelOpen = YES;

    self.textView.text = [[SideNoteStorage sharedInstance] loadNote];

    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat panelX = screenBounds.size.width - kPanelWidth - 10;

    // Panel Y follows tab position, clamped to safe area
    UIEdgeInsets safeInsets = self.overlayWindow.safeAreaInsets;
    CGFloat panelY = self.tabCenterY - kPanelHeight / 2.0;
    CGFloat minPanelY = safeInsets.top + 10;
    CGFloat maxPanelY = screenBounds.size.height - safeInsets.bottom - kPanelHeight - 10;
    panelY = MAX(minPanelY, MIN(maxPanelY, panelY));

    [self.overlayWindow makeKeyAndVisible];

    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.8
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        CGRect pf = self.panelView.frame;
        pf.origin.x = panelX;
        pf.origin.y = panelY;
        self.panelView.frame = pf;

        // Tab sticks to panel left side, vertically centered on panel
        CGRect tf = self.tabView.frame;
        tf.origin.x = panelX - kTabWidth;
        tf.origin.y = panelY + kPanelHeight / 2.0 - kTabHeight / 2.0;
        self.tabView.frame = tf;
    } completion:nil];
}

- (void)closePanel {
    if (!self.panelOpen) return;

    [self.textView resignFirstResponder];
    [[SideNoteStorage sharedInstance] saveNote:self.textView.text ?: @""];

    CGRect screenBounds = [UIScreen mainScreen].bounds;

    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        CGRect pf = self.panelView.frame;
        pf.origin.x = screenBounds.size.width;
        self.panelView.frame = pf;

        // Tab returns to original tabCenterY on right edge
        CGRect tf = self.tabView.frame;
        tf.origin.x = screenBounds.size.width - kTabWidth;
        tf.origin.y = self.tabCenterY - kTabHeight / 2.0;
        self.tabView.frame = tf;
    } completion:^(BOOL finished) {
        self.panelOpen = NO;
        [self.overlayWindow resignKeyWindow];
    }];
}

#pragma mark - Keyboard

- (void)registerKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (!self.panelOpen) return;

    NSDictionary *info = notification.userInfo;
    CGRect kbFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat panelBottom = CGRectGetMaxY(self.panelView.frame);
    CGFloat kbTop = screenHeight - kbFrame.size.height;

    if (panelBottom > kbTop) {
        CGFloat shift = panelBottom - kbTop + 10;
        [UIView animateWithDuration:duration animations:^{
            CGRect pf = self.panelView.frame;
            pf.origin.y -= shift;
            self.panelView.frame = pf;
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!self.panelOpen) return;

    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIEdgeInsets safeInsets = self.overlayWindow.safeAreaInsets;

    [UIView animateWithDuration:duration animations:^{
        CGRect pf = self.panelView.frame;
        pf.origin.y = safeInsets.top + 40;
        self.panelView.frame = pf;
    }];
}

@end
