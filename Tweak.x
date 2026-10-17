#import <UIKit/UIImage+Private.h>
#import <UIKit/UIImageAsset+Private.h>
#import <YouTubeHeader/ASImageNodeDrawParameters.h>
#import <YouTubeHeader/_ASDisplayView.h>
#import <YouTubeHeader/ELMContainerNode.h>
#import <YouTubeHeader/ELMNodeController.h>
#import <YouTubeHeader/UIColor+YouTube.h>
#import <YouTubeHeader/UIImage+YouTube.h>
#import <YouTubeHeader/YTInlineMutedPlaybackScrubberView.h>
#import <YouTubeHeader/YTInlineMutedPlaybackScrubbingSlider.h>
#import <YouTubeHeader/YTIPlayerBarDecorationModel.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTPlayerBarController.h>
#import <YouTubeHeader/YTPlayerBarProgressDecorationView.h>
#import <YouTubeHeader/YTPlayerBarRectangleDecorationView.h>
#import <YouTubeHeader/YTPlayerBarScrubberDotDecorationController.h>
#import <YouTubeHeader/YTPlayerBarScrubberDotDecorationView.h>
#import <YouTubeHeader/YTPlayerBarScrubberDotView.h>
#import <YouTubeHeader/YTPlayerBarSegmentView.h>
#import <YouTubeHeader/YTSegmentableInlinePlayerBarView.h>
#import "Settings.h"

@interface YTModularPlayerBarView (Addition)
@property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;
@end

@interface YTSegmentableInlinePlayerBarView (Addition)
@property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;
@end

@interface YTInlinePlayerBarView (Addition)
@property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;
@end

#define DEFAULT_SCRUBBER_SIZE 12
#define YOUTUBE_SCRUBBER_SCALE 6

extern BOOL IsEnabled(NSString *key);
extern NSString *GetScrubberColor();
extern NSString *GetLiveScrubberColor();
extern UIImage *GetScrubberImage();
extern NSString *GetSliderColor();
extern NSString *GetLiveSliderColor();
extern int GetSelection(NSString *key);

UIColor *sliderUIColor() {
    NSString *color = GetSliderColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

UIColor *liveSliderUIColor() {
    NSString *color = GetLiveSliderColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

UIColor *scrubberUIColor() {
    NSString *color = GetScrubberColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

UIColor *liveScrubberUIColor() {
    NSString *color = GetLiveScrubberColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

static CGFloat getBaseScrubberScale() {
    int scrubberSize = GetSelection(ScrubberSizeKey);
    if (scrubberSize == 0 && !IsEnabled(ScrubberImageKey)) return -1;
    return 1 + (scrubberSize / 100.0);
}

static void updateScrubberSize(UIView *scrubberCircle, CGFloat scale) {
    CGRect frame = scrubberCircle.frame;
    CGFloat size = DEFAULT_SCRUBBER_SIZE * scale;
    if (!IsEnabled(ScrubberImageKey))
        size /= YOUTUBE_SCRUBBER_SCALE;
    scrubberCircle.frame = CGRectMake(frame.origin.x, frame.origin.y, size, size);
    if (!IsEnabled(ScrubberImageKey))
        scrubberCircle.layer.cornerRadius = size / 2;
}

static UIView *getScrubberCircle(UIView *self) {
    @try {
        return [self valueForKey:@"_scrubberCircle"];
    } @catch (id ex) {}
    NSMutableDictionary <NSString *, NSMutableArray *> *decorationCollections = [self valueForKey:@"_decorationCollections"];
    YTPlayerBarScrubberDotDecorationView *scrubberDot = [decorationCollections[@"modular_player_bar_scrubber_dot_collection_key"] firstObject];
    return scrubberDot.scrubberDot;
}

static void initScrubberCircleBase(UIView *scrubberCircle, BOOL setColor) {
    if (scrubberCircle == nil) return;
    CGFloat scrubberScale = getBaseScrubberScale();
    if (scrubberScale == -1) return;
    updateScrubberSize(scrubberCircle, scrubberScale);
    if (setColor) {
        if (IsEnabled(ScrubberImageKey))
            scrubberCircle.backgroundColor = nil;
        else if (IsEnabled(ScrubberImageColorKey)) {
            UIColor *scrubberColor = scrubberUIColor();
            if (!scrubberColor) return;
            scrubberCircle.backgroundColor = scrubberColor;
        }
    }
}

static void initScrubberCircle(UIView *self, BOOL setColor) {
    initScrubberCircleBase(getScrubberCircle(self), setColor);
}

static CGPoint getScrubberCircleCenter(UIView *self) {
    UIView *scrubberCircle = getScrubberCircle(self);
    return scrubberCircle.center;
}

static void updateScrubberColorAndPosition(UIView *self, BOOL alterScrubber, CGPoint originalCenter) {
    UIView *scrubberCircle = getScrubberCircle(self);
    if (scrubberCircle == nil) return;
    if (alterScrubber) {
        if (IsEnabled(ScrubberImageKey))
            scrubberCircle.backgroundColor = nil;
        else if (IsEnabled(ScrubberImageColorKey)) {
            BOOL isLive = [self respondsToSelector:@selector(isVideoModeLive)] && [(id)self isVideoModeLive];
            UIColor *scrubberColor = isLive ? liveScrubberUIColor() : scrubberUIColor();
            if (!scrubberColor) return;
            scrubberCircle.backgroundColor = scrubberColor;
        }
    }
    if (!IsEnabled(AnimatedSliderKey) || CGPointEqualToPoint(originalCenter, CGPointZero)) return;
    CGPoint newCenter = scrubberCircle.center;
    scrubberCircle.center = originalCenter;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        scrubberCircle.center = newCenter;
    } completion:nil];
}

static CGFloat getScrubberScale(CGFloat scale) {
    if (!IsEnabled(ScrubberImageKey)) return scale;
    return scale / YOUTUBE_SCRUBBER_SCALE + 0.00001;
}

static CGFloat getDecorationScrubberScale(CGFloat scale) {
    if (!IsEnabled(ScrubberImageKey)) return scale;
    CGFloat base = getBaseScrubberScale();
    return base > 0 ? scale * base : scale;
}

static CGSize scaledCustomScrubberImageSize(UIView *dot, CGSize youtubeSize) {
    CGFloat base = getBaseScrubberScale();
    if (base <= 0) base = 1;
    CGFloat parent = MIN(dot.bounds.size.width, dot.bounds.size.height);
    if (parent > 2.0)
        return CGSizeMake(parent, parent);
    CGFloat youtube = MAX(youtubeSize.width, youtubeSize.height);
    CGFloat rest = DEFAULT_SCRUBBER_SIZE * base;
    if (youtube >= 20.0 && youtube < 24.0) {
        CGFloat drag = rest * (20.0 / DEFAULT_SCRUBBER_SIZE);
        return CGSizeMake(drag, drag);
    }
    return CGSizeMake(rest, rest);
}

static UIImage *effectiveCustomScrubberIcon(UIImage *image, BOOL *applied) {
    *applied = YES;
    if (!IsEnabled(ScrubberImageKey)) return image;
    UIImage *userImage = GetScrubberImage();
    if (!userImage) {
        *applied = NO;
        return nil;
    }
    return userImage;
}

static void applyDecorationScrubberColor(YTPlayerBarScrubberDotDecorationView *decorationView) {
    if (![decorationView respondsToSelector:@selector(setScrubberDotColor:)]) return;
    if (IsEnabled(ScrubberImageKey)) {
        [decorationView setScrubberDotColor:nil];
        return;
    }
    if (!IsEnabled(ScrubberImageColorKey)) return;
    UIColor *color = scrubberUIColor();
    if (color)
        [decorationView setScrubberDotColor:color];
}

static void setTweakCustomScrubberIcon(id self_, UIView *scrubberCircle) {
    YTModularPlayerBarView *self = self_;
    UIImageView *imageView = self.tweakCustomScrubberImageView;
    if (scrubberCircle == nil)
        scrubberCircle = [self valueForKey:@"_scrubberCircle"];
    if (IsEnabled(ScrubberImageKey)) {
        UIImage *image = GetScrubberImage();
        if (!image) return;
        [imageView removeFromSuperview];
        self.tweakCustomScrubberImageView = [[UIImageView alloc] initWithImage:image];
        self.tweakCustomScrubberImageView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat scrubberScale = getBaseScrubberScale();
        CGFloat size = DEFAULT_SCRUBBER_SIZE * scrubberScale;
        self.tweakCustomScrubberImageView.frame = CGRectMake(0, 0, size, size);
        scrubberCircle.backgroundColor = [UIColor clearColor];
        [scrubberCircle addSubview:self.tweakCustomScrubberImageView];
    } else {
        [imageView removeFromSuperview];
        self.tweakCustomScrubberImageView = nil;
        updateScrubberColorAndPosition(self, YES, CGPointZero);
    }
}

static __weak YTMainAppVideoPlayerOverlayViewController *currentOverlayVC;
static id settingsObserver;
static void findViewAndSetScrubberIcon(YTMainAppVideoPlayerOverlayViewController *self);

static void setNeedsDisplayRecursive(UIView *view) {
    [view setNeedsDisplay];
    [view setNeedsLayout];
    for (UIView *subview in view.subviews)
        setNeedsDisplayRecursive(subview);
}

static void forceDecorationScaleRefresh(YTPlayerBarScrubberDotDecorationView *decorationView) {
    if (![decorationView respondsToSelector:@selector(transformScrubberScale:)]) return;
    CGFloat youtubeScale = 6.0;
    @try {
        NSInteger scaleEnum = [[decorationView valueForKey:@"_scrubberDotDecorationScale"] integerValue];
        if (scaleEnum <= 0)
            youtubeScale = 0;
        else if (scaleEnum == 2)
            youtubeScale = [[decorationView valueForKey:@"_dragEnlargedScale"] doubleValue] ?: 10;
        else
            youtubeScale = [[decorationView valueForKey:@"_enlargedScale"] doubleValue] ?: 6;
    } @catch (id ex) {}
    [decorationView transformScrubberScale:youtubeScale + 0.01];
    [decorationView transformScrubberScale:youtubeScale];
    [decorationView setNeedsLayout];
    [decorationView layoutIfNeeded];
}

static void refreshCurrentScrubber() {
    YTMainAppVideoPlayerOverlayViewController *overlay = currentOverlayVC;
    if (![overlay respondsToSelector:@selector(playerBarController)]) return;
    findViewAndSetScrubberIcon(overlay);
    YTInlinePlayerBarContainerView *playerBar = overlay.playerBarController.playerBar;
    if (!playerBar) return;
    setNeedsDisplayRecursive(playerBar);
    YTPlayerBarScrubberDotDecorationView *decorationView = nil;
    @try {
        YTPlayerBarScrubberDotDecorationController *controller = [playerBar valueForKey:@"_scrubberDotDecorationController"];
        decorationView = [controller scrubberDot];
    } @catch (id ex) {}
    if (decorationView) {
        forceDecorationScaleRefresh(decorationView);
        return;
    }
    id view = nil;
    if ([playerBar respondsToSelector:@selector(modularPlayerBar)] && playerBar.modularPlayerBar)
        view = playerBar.modularPlayerBar.view;
    else if ([playerBar respondsToSelector:@selector(segmentablePlayerBar)] && playerBar.segmentablePlayerBar) {
        id segmentablePlayerBar = playerBar.segmentablePlayerBar;
        if ([segmentablePlayerBar isKindOfClass:%c(YTModularPlayerBarController)])
            view = ((YTModularPlayerBarController *)segmentablePlayerBar).view;
        else
            view = segmentablePlayerBar;
    } else
        view = playerBar.playerBar;
    if (view)
        initScrubberCircle(view, YES);
}

static void findViewAndSetScrubberIcon(YTMainAppVideoPlayerOverlayViewController *self) {
    currentOverlayVC = self;
    YTInlinePlayerBarContainerView *playerBar = self.playerBarController.playerBar;
    id view;
    if ([playerBar respondsToSelector:@selector(modularPlayerBar)]) {
        view = playerBar.modularPlayerBar.view;
        @try {
            YTPlayerBarScrubberDotDecorationController *scrubberDotDecorationController = [playerBar valueForKey:@"_scrubberDotDecorationController"];
            if (scrubberDotDecorationController) {
                YTPlayerBarScrubberDotDecorationView *scrubberDotDecorationView = [scrubberDotDecorationController scrubberDot];
                if ([scrubberDotDecorationView respondsToSelector:@selector(setCustomImageScrubberIcon:)]) {
                    UIImage *image = IsEnabled(ScrubberImageKey) ? GetScrubberImage() : nil;
                    [scrubberDotDecorationView setCustomImageScrubberIcon:image];
                    applyDecorationScrubberColor(scrubberDotDecorationView);
                    if ([view respondsToSelector:@selector(tweakCustomScrubberImageView)]) {
                        [[view tweakCustomScrubberImageView] removeFromSuperview];
                        [view setTweakCustomScrubberImageView:nil];
                    }
                    return;
                }
                UIView *scrubberCircle = scrubberDotDecorationView.scrubberDot; // Or YTPlayerBarScrubberDotView
                setTweakCustomScrubberIcon(view, scrubberCircle);
                return;
            }
        } @catch (id ex) {}
    }
    else if ([playerBar respondsToSelector:@selector(segmentablePlayerBar)] && playerBar.segmentablePlayerBar) {
        id segmentablePlayerBar = playerBar.segmentablePlayerBar;
        if ([segmentablePlayerBar isKindOfClass:%c(YTModularPlayerBarController)])
            view = ((YTModularPlayerBarController *)segmentablePlayerBar).view;
        else
            view = segmentablePlayerBar; // YTSegmentableInlinePlayerBarView
    } else
        view = playerBar.playerBar;
    setTweakCustomScrubberIcon(view, nil);
}

%hook YTModularPlayerBarView

%property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;

- (id)initWithModel:(id)model delegate:(id)delegate {
    self = %orig;
    if (self)
        initScrubberCircle(self, NO);
    return self;
}

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getScrubberScale(scale));
}

- (void)setCustomScrubberIcon:(UIImage *)image {
    BOOL applied;
    image = effectiveCustomScrubberIcon(image, &applied);
    if (!applied) return;
    %orig(image);
}

- (void)maybeSetDefaultScrubberBackgroundColor {
    %orig;
    UIView *scrubberCircle = getScrubberCircle(self);
    if (IsEnabled(ScrubberImageKey))
        scrubberCircle.backgroundColor = [UIColor clearColor];
    if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (!scrubberColor) return;
        scrubberCircle.backgroundColor = scrubberColor;
    }
}

- (void)layoutSubviews {
    CGPoint center = getScrubberCircleCenter(self);
    %orig;
    updateScrubberColorAndPosition(self, NO, center);
}

%end

%hook YTSegmentableInlinePlayerBarView

%property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;

- (id)init {
    self = %orig;
    if (self)
        initScrubberCircle(self, NO);
    return self;
}

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getScrubberScale(scale));
}

- (void)setMode:(int)mode {
    %orig;
    updateScrubberColorAndPosition(self, YES, CGPointZero);
}

- (void)resetPlayerBarModeColors {
    %orig;
    if (IsEnabled(SliderColorKey)) {
        BOOL isLive = [self isVideoModeLive];
        UIColor *color = isLive ? liveSliderUIColor() : sliderUIColor();
        if (!color) return;
        [self setValue:color forKey:@"_progressBarColor"];
        [self setValue:color forKey:@"_userIsScrubbingProgressBarColor"];
    }
    updateScrubberColorAndPosition(self, YES, CGPointZero);
}

- (void)layoutSubviews {
    CGPoint center = getScrubberCircleCenter(self);
    %orig;
    updateScrubberColorAndPosition(self, NO, center);
}

%end

%hook YTInlinePlayerBarView

%property (retain, nonatomic) UIImageView *tweakCustomScrubberImageView;

- (id)init {
    self = %orig;
    if (self) {
        initScrubberCircle(self, YES);
    }
    return self;
}

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getScrubberScale(scale));
}

- (void)setMode:(int)mode {
    %orig;
    updateScrubberColorAndPosition(self, YES, CGPointZero);
    if (IsEnabled(SliderColorKey)) {
        UIColor *color = mode == PLAYER_BAR_MODE_LIVE || mode == PLAYER_BAR_MODE_LIVE_VDR ? liveSliderUIColor() : sliderUIColor();
        if (color) {
            UIView *playingProgress = [self valueForKey:@"_playingProgress"];
            playingProgress.backgroundColor = color;
        }
    }
}

- (void)layoutSubviews {
    CGPoint center = getScrubberCircleCenter(self);
    %orig;
    updateScrubberColorAndPosition(self, NO, center);
}

%end

static void setSliderColorIfNeeded(YTPlayerBarSegmentView *self, CGRect rect) {
    if (!IsEnabled(SliderColorKey)) return;
    UIColor *color = sliderUIColor();
    if (!color) return;
    CGFloat playingProgress = [[self valueForKey:@"_playingProgress"] doubleValue];
    CGRect fillRect = CGRectMake(0, 0, rect.size.width * playingProgress, rect.size.height);
    [color setFill];
    UIRectFill(fillRect);
}

%hook YTPlayerBarSegmentView

- (void)drawHighlightedChapter:(CGRect)rect {
    if (IsEnabled(AnimatedSliderKey))
        [UIView
            transitionWithView:self
            duration:0.2
            options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveLinear
            animations:^{
                %orig;
                setSliderColorIfNeeded(self, rect);
            }
            completion:nil];
    else {
        %orig;
        setSliderColorIfNeeded(self, rect);
    }
}

- (void)drawUnhighlightedChapter:(CGRect)rect {
    if (IsEnabled(AnimatedSliderKey))
        [UIView
            transitionWithView:self
            duration:0.2
            options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveLinear
            animations:^{
                %orig;
                setSliderColorIfNeeded(self, rect);
            }
            completion:nil];
    else {
        %orig;
        setSliderColorIfNeeded(self, rect);
    }
}

%end

%hook YTColor

+ (BOOL)cairoRefreshSignatureMomentsEnabled {
    return IsEnabled(SliderColorKey) ? NO : %orig;
}

%end

%hook YTPlayerBarProgressDecorationView

- (BOOL)shouldApplyGradientColor {
    return IsEnabled(SliderColorKey) ? NO : %orig;
}

- (void)drawProgressRect:(CGRect)rect withColor:(UIColor *)color {
    YTIPlayerBarDecorationModel *model = [self valueForKey:@"_model"];
    BOOL isLive = model.playingState.mode == PLAYER_BAR_MODE_LIVE || model.playingState.mode == PLAYER_BAR_MODE_LIVE_VDR;
    UIColor *targetColor = IsEnabled(SliderColorKey) ? (isLive ? liveSliderUIColor() : sliderUIColor()) : color;
    if (IsEnabled(AnimatedSliderKey))
        [UIView
            transitionWithView:self
            duration:0.2
            options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveLinear
            animations:^{
                %orig(rect, targetColor);
            }
            completion:nil];
    else
        %orig(rect, targetColor);
}

%end

%hook YTPlayerBarRectangleDecorationView

- (void)drawRectangleDecorationWithSideMasks:(CGRect)rect {
    if (IsEnabled(SliderColorKey)) {
        YTIPlayerBarDecorationModel *model = [self valueForKey:@"_model"];
        YTIPlayerBarPlayingStateOverlayMode overlayMode = model.playingState.overlayMode;
        model.playingState.overlayMode = PLAYER_BAR_OVERLAY_MODE_DEFAULT;
        if ([model respondsToSelector:@selector(style)] && [model.style respondsToSelector:@selector(gradientColor)])
            model.style.gradientColor = nil;
        %orig;
        model.playingState.overlayMode = overlayMode;
    } else
        %orig;
}

- (void)drawProgressRect:(CGRect)rect withColor:(UIColor *)color {
    YTIPlayerBarDecorationModel *model = [self valueForKey:@"_model"];
    BOOL isLive = model.playingState.mode == PLAYER_BAR_MODE_LIVE || model.playingState.mode == PLAYER_BAR_MODE_LIVE_VDR;
    UIColor *targetColor = IsEnabled(SliderColorKey) ? (isLive ? liveSliderUIColor() : sliderUIColor()) : color;
    if (IsEnabled(AnimatedSliderKey))
        [UIView
            transitionWithView:self
            duration:0.2
            options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveLinear
            animations:^{
                %orig(rect, targetColor);
            }
            completion:nil];
    else
        %orig(rect, targetColor);
}

%end

%hook YTInlinePlayerBarContainerView

- (void)setCustomScrubberIcon:(UIImage *)image {
    BOOL applied;
    image = effectiveCustomScrubberIcon(image, &applied);
    if (!applied) return;
    %orig(image);
}

%end

@interface YTPlayerBarScrubberDotDecorationViewV1 : YTPlayerBarScrubberDotDecorationView
@end

@interface YTPlayerBarScrubberDotDecorationViewV2 : YTPlayerBarScrubberDotDecorationView
@end

%hook YTPlayerBarScrubberDotView

- (void)setCustomScrubberImageViewSize:(CGSize)size {
    if (IsEnabled(ScrubberImageKey))
        size = scaledCustomScrubberImageSize(self, size);
    %orig(size);
}

%end

%hook YTPlayerBarScrubberDotDecorationViewV2

- (void)transformScrubberScale:(CGFloat)scale {
    CGFloat base = getBaseScrubberScale();
    if (base != -1)
        scale *= base;
    %orig(scale);
}

- (void)setCustomImageScrubberIcon:(UIImage *)image {
    BOOL applied;
    image = effectiveCustomScrubberIcon(image, &applied);
    if (!applied) return;
    %orig(image);
}

- (void)setScrubberDotColor:(UIColor *)color {
    if (IsEnabled(ScrubberImageKey))
        color = nil;
    else if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (scrubberColor) color = scrubberColor;
    }
    %orig(color);
}

- (void)updateFrameWithPlayerBarFrame:(CGRect)frame {
    if (IsEnabled(AnimatedSliderKey))
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            %orig;
        } completion:nil];
    else
        %orig;
}

%end

%hook YTPlayerBarScrubberDotDecorationViewV1

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getDecorationScrubberScale(scale));
}

- (void)setCustomImageScrubberIcon:(UIImage *)image {
    BOOL applied;
    image = effectiveCustomScrubberIcon(image, &applied);
    if (!applied) return;
    %orig(image);
}

- (void)setScrubberDotColor:(UIColor *)color {
    if (IsEnabled(ScrubberImageKey))
        color = nil;
    else if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (scrubberColor) color = scrubberColor;
    }
    %orig(color);
}

- (UIView *)expectedScrubberDot {
    UIView *scrubberCircle = %orig;
    if (!scrubberCircle) return nil;
    if (IsEnabled(ScrubberImageKey))
        scrubberCircle.backgroundColor = [UIColor clearColor];
    else if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (!scrubberColor) return scrubberCircle;
        scrubberCircle.backgroundColor = scrubberColor;
    }
    return scrubberCircle;
}

- (void)updateFrameWithPlayerBarFrame:(CGRect)frame {
    if (IsEnabled(AnimatedSliderKey))
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            %orig;
        } completion:nil];
    else
        %orig;
}

%end

%hook YTPlayerBarScrubberDotDecorationView

- (id)initWithModel:(id)model {
    self = %orig;
    if (self) {
        if (!IsEnabled(ScrubberImageKey))
            initScrubberCircleBase([self valueForKey:@"_defaultScrubberDot"], YES);
        applyDecorationScrubberColor(self);
    }
    return self;
}

- (UIView *)expectedScrubberDot {
    UIView *scrubberCircle = %orig;
    if (!scrubberCircle) return nil;
    if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (!scrubberColor) return scrubberCircle;
        scrubberCircle.backgroundColor = scrubberColor;
    }
    return scrubberCircle;
}

- (void)transformScrubberScale:(CGFloat)scale {
    %orig(getDecorationScrubberScale(scale));
}

- (void)setCustomImageScrubberIcon:(UIImage *)image {
    BOOL applied;
    image = effectiveCustomScrubberIcon(image, &applied);
    if (!applied) return;
    %orig(image);
}

- (void)updateFrameWithPlayerBarFrame:(CGRect)frame {
    if (IsEnabled(AnimatedSliderKey))
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            %orig;
        } completion:nil];
    else
        %orig;
}

%end

%hook YTProgressView

- (void)layoutSubviews {
    if (IsEnabled(AnimatedSliderKey))
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            %orig;
        } completion:nil];
    else
        %orig;
}

- (void)setProgressBarColor:(UIColor *)color {
    %orig(IsEnabled(SliderColorKey) ? sliderUIColor() : color);
}

- (void)setBrandGradientEnabled:(BOOL)enabled {
    %orig(IsEnabled(SliderColorKey) ? NO : enabled);
}

%end

%hook YTInlineMutedPlaybackScrubberView

- (void)addGradient {
    if (IsEnabled(SliderColorKey)) return;
    %orig;
}

- (void)initScrubberWithMode:(int)mode {
    %orig;
    if (mode == 0) return;
    YTInlineMutedPlaybackScrubbingSlider *slider = [self valueForKey:@"_playingProgress"];
    if (IsEnabled(SliderColorKey)) {
        UIColor *color = sliderUIColor();
        if (color)
            [slider setMinimumTrackImage:[slider.currentMinimumTrackImage _flatImageWithColor:color] forState:UIControlStateNormal];
    }
}

%end

%hook YTInlineMutedPlaybackScrubbingSlider

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state {
    if (![self.accessibilityIdentifier isEqualToString:@"id.player.scrubber.slider"] || [image.imageAsset.assetName isEqualToString:@"transparent"]) {
        %orig;
        return;
    }
    CGSize originalSize = image.size;
    if (IsEnabled(ScrubberImageKey)) {
        UIImage *newImage = GetScrubberImage();
        if (newImage) {
            originalSize = CGSizeMake(DEFAULT_SCRUBBER_SIZE, DEFAULT_SCRUBBER_SIZE);
            image = newImage;
        }
    } else if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (scrubberColor)
            image = [image _flatImageWithColor:scrubberColor];
    }
    CGFloat scrubberScale = getBaseScrubberScale();
    if (scrubberScale != -1)
        image = [image yt_imageScaledToSize:CGSizeMake(originalSize.width * scrubberScale, originalSize.height * scrubberScale)];
    %orig;
}

%end

%hook YTMainAppVideoPlayerOverlayViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    currentOverlayVC = self;
}

- (void)setWatchNextResponse:(id)response loading:(BOOL)loading {
    findViewAndSetScrubberIcon(self);
    %orig;
}

- (void)setWatchNextResponse:(id)response {
    findViewAndSetScrubberIcon(self);
    %orig;
}

%end

%hook YTBrandGradientImageProcessor

- (void)willDrawInContext:(CGContextRef)ctx drawParameters:(ASImageNodeDrawParameters *)drawParameters {
    if (IsEnabled(SliderColorKey)) {
        UIColor *color = sliderUIColor();
        if (color) {
            CGRect totalRect = CGContextGetClipBoundingBox(ctx);
            CGRect progressRect = CGRectIntersection([drawParameters drawRect], totalRect);
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillRect(ctx, progressRect);
            return;
        }
    }
    %orig;
}

%end

static ELMNodeController *getNodeControllerParent(ELMNodeController *nodeController) {
    if ([nodeController respondsToSelector:@selector(parent)])
        return nodeController.parent;
    return [nodeController.node.yogaParent controller];
}

%hook _ASDisplayView

- (void)didMoveToSuperview {
    %orig;
    if (self.bounds.size.height) return;
    ELMContainerNode *containerNode = (ELMContainerNode *)self.keepalive_node;
    if (![containerNode isKindOfClass:%c(ELMContainerNode)]) return;
    UIColor *currentColor = [containerNode valueForKey:@"_stretchableBackgroundColor"];
    if (currentColor == nil || ![currentColor isEqual:[UIColor colorWithRGBValue:0xFF0000 floatAlpha:1]]) return;
    ASDisplayNode *node = nil;
    ELMNodeController *nodeController = [containerNode controller];
    do {
        node = nodeController.node;
        if ([node.accessibilityIdentifier isEqualToString:@"eml.thumbnail"])
            break;
        nodeController = getNodeControllerParent(nodeController);
    } while (nodeController);
    if (![node.accessibilityIdentifier isEqualToString:@"eml.thumbnail"]) return;
    if (!IsEnabled(SliderColorKey)) return;
    UIColor *color = sliderUIColor();
    if (color == nil) return;
    [containerNode setValue:color forKey:@"_stretchableBackgroundColor"];
    self.backgroundColor = color;
}

%end

%ctor {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        EnabledKey: @YES,
    }];
    if (!IsEnabled(EnabledKey)) return;
    %init;
    settingsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:YouSliderSettingsChangedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        refreshCurrentScrubber();
    }];
}
