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
#import <YouTubeHeader/YTPlayerBarRectangleDecorationView.h>
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
extern UIImage *GetScrubberImage();
extern NSString *GetSliderColor();
extern int GetSelection(NSString *key);

UIColor *sliderUIColor() {
    NSString *color = GetSliderColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

UIColor *scrubberUIColor() {
    NSString *color = GetScrubberColor();
    return color ? [UIColor LOT_colorWithHexString:color] : nil;
}

static CGFloat getBaseScrubberScale() {
    int scrubberSize = GetSelection(ScrubberSizeKey);
    if (scrubberSize == 0 && !IsEnabled(ScrubberImageKey)) return -1;
    return 1 + (scrubberSize / 100.0);;
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

static void initScrubberCircle(UIView *self, BOOL setColor) {
    CGFloat scrubberScale = getBaseScrubberScale();
    if (scrubberScale == -1) return;
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
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

static CGPoint getScrubberCircleCenter(UIView *self) {
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
    return scrubberCircle.center;
}

static void updateScrubberColorAndPosition(UIView *self, BOOL alterScrubber, CGPoint originalCenter) {
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
    if (alterScrubber) {
        if (IsEnabled(ScrubberImageKey))
            scrubberCircle.backgroundColor = nil;
        else if (IsEnabled(ScrubberImageColorKey)) {
            UIColor *scrubberColor = scrubberUIColor();
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

static void setTweakCustomScrubberIcon(id self_) {
    YTModularPlayerBarView *self = self_;
    UIImageView *imageView = self.tweakCustomScrubberImageView;
    UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
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

static void findViewAndSetScrubberIcon(YTMainAppVideoPlayerOverlayViewController *self) {
    YTInlinePlayerBarContainerView *playerBar = self.playerBarController.playerBar;
    id view;
    if ([playerBar respondsToSelector:@selector(modularPlayerBar)])
        view = playerBar.modularPlayerBar.view;
    else if ([playerBar respondsToSelector:@selector(segmentablePlayerBar)] && playerBar.segmentablePlayerBar) {
        id segmentablePlayerBar = playerBar.segmentablePlayerBar;
        if ([segmentablePlayerBar isKindOfClass:%c(YTModularPlayerBarController)])
            view = ((YTModularPlayerBarController *)segmentablePlayerBar).view;
        else
            view = segmentablePlayerBar; // YTSegmentableInlinePlayerBarView
    } else
        view = playerBar.playerBar;
    setTweakCustomScrubberIcon(view);
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
    if (IsEnabled(ScrubberImageKey)) return;
    %orig;
}

- (void)maybeSetDefaultScrubberBackgroundColor {
    %orig;
    if (IsEnabled(ScrubberImageColorKey)) {
        UIColor *scrubberColor = scrubberUIColor();
        if (!scrubberColor) return;
        UIView *scrubberCircle = [self valueForKey:@"_scrubberCircle"];
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
        UIColor *color = sliderUIColor();
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
        UIColor *color = sliderUIColor();
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
    if (IsEnabled(AnimatedSliderKey))
        [UIView
            transitionWithView:self
            duration:0.2
            options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveLinear
            animations:^{
                %orig(rect, IsEnabled(SliderColorKey) ? sliderUIColor() : color);
            }
            completion:nil];
    else
        %orig(rect, IsEnabled(SliderColorKey) ? sliderUIColor() : color);
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
}
