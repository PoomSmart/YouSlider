#import <PSHeader/Misc.h>
#import <YouTubeHeader/YTAlertView.h>
#import <YouTubeHeader/YTSettingsGroupData.h>
#import <YouTubeHeader/YTSettingsPickerViewController.h>
#import <YouTubeHeader/YTSettingsSectionItem.h>
#import <YouTubeHeader/YTSettingsSectionItemManager.h>
#import <YouTubeHeader/YTSettingsViewController.h>
#import <YouTubeHeader/YTUIUtils.h>
#import <YouTubeHeader/UIColor+YouTube.h>
#import <UIKit/UIImage+Private.h>
#import "Alderis.h"
#import "Settings.h"

#define _LOC(b, x) [b localizedStringForKey:x value:nil table:nil]
#define LOC(x) _LOC(tweakBundle, x)

static const NSInteger TweakSection = 'ytsl';

@interface YTSettingsSectionItemManager (Tweak)
- (void)updateYouSliderSectionWithEntry:(id)entry;
@end

extern UIColor *scrubberUIColor();
extern UIColor *scrubberUIColor();
extern UIColor *liveScrubberUIColor();
extern UIColor *sliderUIColor();
extern UIColor *liveSliderUIColor();

BOOL IsEnabled(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

NSString *GetSliderColor() {
    return [[NSUserDefaults standardUserDefaults] stringForKey:SliderColorValueKey];
}

NSString *GetLiveSliderColor() {
    return [[NSUserDefaults standardUserDefaults] stringForKey:LiveSliderColorValueKey];
}

NSString *GetScrubberColor() {
    return [[NSUserDefaults standardUserDefaults] stringForKey:ScrubberImageColorValueKey];
}

NSString *GetLiveScrubberColor() {
    return [[NSUserDefaults standardUserDefaults] stringForKey:LiveScrubberImageColorValueKey];
}

UIImage *coloredImage(UIImage *image) {
    if (!IsEnabled(ScrubberImageColorKey)) return image;
    UIColor *color = scrubberUIColor();
    if (color)
        return [image _flatImageWithColor:color];
    return image;
}

UIImage *GetScrubberImage() {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", ScrubberImageKey]];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    return coloredImage(image);;
}

int GetSelection(NSString *key) {
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

NSBundle *TweakBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:TweakName ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: PS_ROOT_PATH_NS(@"/Library/Application Support/" TweakName ".bundle")];
    });
    return bundle;
}

%hook YTSettingsGroupData

- (NSArray <NSNumber *> *)orderedCategories {
    if (self.type != 1 || class_getClassMethod(objc_getClass("YTSettingsGroupData"), @selector(tweaks)))
        return %orig;
    NSMutableArray <NSNumber *> *mutableCategories = %orig.mutableCopy;
    [mutableCategories insertObject:@(TweakSection) atIndex:0];
    return mutableCategories.copy;
}

%end

%hook YTAppSettingsPresentationData

+ (NSArray <NSNumber *> *)settingsCategoryOrder {
    NSArray <NSNumber *> *order = %orig;
    NSUInteger insertIndex = [order indexOfObject:@(1)];
    if (insertIndex != NSNotFound) {
        NSMutableArray <NSNumber *> *mutableOrder = [order mutableCopy];
        [mutableOrder insertObject:@(TweakSection) atIndex:insertIndex + 1];
        order = mutableOrder.copy;
    }
    return order;
}

%end

%hook YTSettingsSectionItemManager

%new(v@:@@)
- (void)colorPicker:(HBColorPickerViewController *)colorPicker didSelectColor:(UIColor *)color {
    NSString *key;
    if ([colorPicker.title isEqualToString:@"Slider"])
        key = SliderColorValueKey;
    else if ([colorPicker.title isEqualToString:@"Live Slider"])
        key = LiveSliderColorValueKey;
    else if ([colorPicker.title isEqualToString:@"Scrubber"])
        key = ScrubberImageColorValueKey;
    else if ([colorPicker.title isEqualToString:@"Live Scrubber"])
        key = LiveScrubberImageColorValueKey;
    else
        return;
    NSString *hex = [color LOT_hexStringValue];
    [[NSUserDefaults standardUserDefaults] setObject:hex forKey:key];
    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];
    [settingsViewController reloadData];
}

%new(v@:@)
- (void)updateYouSliderSectionWithEntry:(id)entry {
    NSMutableArray *sectionItems = [NSMutableArray array];
    NSBundle *tweakBundle = TweakBundle();
    NSString *yesText = _LOC([NSBundle mainBundle], @"settings.yes");
    Class YTAlertViewClass = %c(YTAlertView);
    Class YTSettingsSectionItemClass = %c(YTSettingsSectionItem);
    YTSettingsViewController *settingsViewController = [self valueForKey:@"_settingsViewControllerDelegate"];

    // Master switch
    YTSettingsSectionItem *master = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"ENABLED")
        titleDescription:LOC(@"ENABLED_DESC")
        accessibilityIdentifier:nil
        switchOn:IsEnabled(EnabledKey)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:EnabledKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:master];

    // Slider color toggle
    YTSettingsSectionItem *sliderColorToggle = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"SLIDER_COLOR")
        titleDescription:LOC(@"SLIDER_COLOR_DESC")
        accessibilityIdentifier:nil
        switchOn:IsEnabled(SliderColorKey)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:SliderColorKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:sliderColorToggle];

    // Slider color value
    YTSettingsSectionItem *sliderColor = [YTSettingsSectionItemClass itemWithTitle:LOC(@"SLIDER_COLOR_VALUE")
        titleDescription:nil
        accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return GetSliderColor();
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            HBColorPickerViewController *picker = [HBColorPickerViewController new];
            picker.title = @"Slider";
            picker.delegate = (NSObject <HBColorPickerDelegate> *)self;
            picker.popoverPresentationController.sourceView = cell;
            UIColor *color = sliderUIColor();
            HBColorPickerConfiguration *config = [[HBColorPickerConfiguration alloc] initWithColor:color];
            config.supportsAlpha = NO;
            picker.configuration = config;
            [[%c(YTUIUtils) topViewControllerForPresenting] presentViewController:picker animated:YES completion:nil];
            return YES;
        }];
    [sectionItems addObject:sliderColor];

    // Live slider color value
    YTSettingsSectionItem *liveSliderColor = [YTSettingsSectionItemClass itemWithTitle:LOC(@"LIVE_SLIDER_COLOR_VALUE")
        titleDescription:nil
        accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return GetLiveSliderColor();
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            HBColorPickerViewController *picker = [HBColorPickerViewController new];
            picker.title = @"Live Slider";
            picker.delegate = (NSObject <HBColorPickerDelegate> *)self;
            picker.popoverPresentationController.sourceView = cell;
            UIColor *color = liveSliderUIColor();
            HBColorPickerConfiguration *config = [[HBColorPickerConfiguration alloc] initWithColor:color];
            config.supportsAlpha = NO;
            picker.configuration = config;
            [[%c(YTUIUtils) topViewControllerForPresenting] presentViewController:picker animated:YES completion:nil];
            return YES;
        }];
    [sectionItems addObject:liveSliderColor];

    // Scrubber color toggle
    YTSettingsSectionItem *scrubberColorToggle = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"SCRUBBER_COLOR")
        titleDescription:LOC(@"SCRUBBER_COLOR_DESC")
        accessibilityIdentifier:nil
        switchOn:IsEnabled(ScrubberImageColorKey)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ScrubberImageColorKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:scrubberColorToggle];

    // Scrubber color value
    YTSettingsSectionItem *scrubberColor = [YTSettingsSectionItemClass itemWithTitle:LOC(@"SCRUBBER_COLOR_VALUE")
        titleDescription:nil
        accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return GetScrubberColor();
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            HBColorPickerViewController *picker = [HBColorPickerViewController new];
            picker.title = @"Scrubber";
            picker.delegate = (NSObject <HBColorPickerDelegate> *)self;
            picker.popoverPresentationController.sourceView = cell;
            UIColor *color = scrubberUIColor();
            HBColorPickerConfiguration *config = [[HBColorPickerConfiguration alloc] initWithColor:color];
            config.supportsAlpha = NO;
            picker.configuration = config;
            [[%c(YTUIUtils) topViewControllerForPresenting] presentViewController:picker animated:YES completion:nil];
            return YES;
        }];
    [sectionItems addObject:scrubberColor];

    // Live scrubber color value
    YTSettingsSectionItem *liveScrubberColor = [YTSettingsSectionItemClass itemWithTitle:LOC(@"LIVE_SCRUBBER_COLOR_VALUE")
        titleDescription:nil
        accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            return GetLiveScrubberColor();
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            HBColorPickerViewController *picker = [HBColorPickerViewController new];
            picker.title = @"Live Scrubber";
            picker.delegate = (NSObject <HBColorPickerDelegate> *)self;
            picker.popoverPresentationController.sourceView = cell;
            UIColor *color = liveScrubberUIColor();
            HBColorPickerConfiguration *config = [[HBColorPickerConfiguration alloc] initWithColor:color];
            config.supportsAlpha = NO;
            picker.configuration = config;
            [[%c(YTUIUtils) topViewControllerForPresenting] presentViewController:picker animated:YES completion:nil];
            return YES;
        }];
    [sectionItems addObject:liveScrubberColor];

    // Scrubber image toggle
    YTSettingsSectionItem *scrubberImageToggle = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"SCRUBBER_IMAGE")
        titleDescription:LOC(@"SCRUBBER_IMAGE_DESC")
        accessibilityIdentifier:nil
        switchOn:IsEnabled(ScrubberImageKey)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:ScrubberImageKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:scrubberImageToggle];

    // Import scrubber image
    YTSettingsSectionItem *import = [YTSettingsSectionItemClass itemWithTitle:LOC(@"IMPORT_IMAGE")
        titleDescription:LOC(@"IMPORT_IMAGE_DESC")
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            UIImage *image = pasteboard.image;
            if (image) {
                BOOL imageTooLarge = image.size.width > 48 || image.size.height > 48;
                if (imageTooLarge) {
                    YTAlertView *alertView = [YTAlertViewClass infoDialog];
                    alertView.title = LOC(@"IMAGE_TOO_LARGE");
                    alertView.subtitle = LOC(@"IMAGE_TOO_LARGE_DESC");
                    [alertView show];
                    return YES;
                }
                YTAlertView *alertView = [YTAlertViewClass confirmationDialogWithAction:^{
                    NSData *imageData = UIImagePNGRepresentation(image);
                    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", ScrubberImageKey]];
                    [imageData writeToFile:filePath atomically:YES];
                } actionTitle:yesText];
                alertView.title = LOC(@"IMPORT_THIS_IMAGE");
                alertView.subtitle = LOC(@"IMPORT_THIS_IMAGE_DESC");
                alertView.icon = coloredImage(image);
                [alertView show];
            } else {
                YTAlertView *alertView = [YTAlertViewClass infoDialog];
                alertView.title = LOC(@"NO_IMAGE");
                alertView.subtitle = LOC(@"NO_IMAGE_DESC");
                [alertView show];
            }

            return YES;
        }];
    [sectionItems addObject:import];

    // View current image
    YTSettingsSectionItem *viewImage = [YTSettingsSectionItemClass itemWithTitle:LOC(@"VIEW_CURRENT_IMAGE")
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            UIImage *image = GetScrubberImage();
            if (image) {
                YTAlertView *alertView = [YTAlertViewClass infoDialog];
                alertView.icon = image;
                [alertView show];
            }
            return YES;
        }];
    [sectionItems addObject:viewImage];

    // Scrubber size
    NSString *title = LOC(@"SCRUBBER_SIZE");
    YTSettingsSectionItem *scrubberSize = [YTSettingsSectionItemClass itemWithTitle:title
        titleDescription:LOC(@"SCRUBBER_SIZE_DESC")
        accessibilityIdentifier:nil
        detailTextBlock:^NSString *() {
            int selection = GetSelection(ScrubberSizeKey);
            return selection ? [NSString stringWithFormat:@"%d%%", selection] : LOC(@"SCRUBBER_SIZE_DEFAULT");
        }
        selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
            NSMutableArray <YTSettingsSectionItem *> *rows = [NSMutableArray array];
            for (int i = 0; i <= 200; i += 5) {
                NSString *sizeTitle = i ? [NSString stringWithFormat:@"%d%%", i] : LOC(@"SCRUBBER_SIZE_DEFAULT");
                YTSettingsSectionItem *size = [YTSettingsSectionItemClass checkmarkItemWithTitle:sizeTitle titleDescription:nil selectBlock:^BOOL (YTSettingsCell *cell, NSUInteger arg1) {
                    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:ScrubberSizeKey];
                    [settingsViewController reloadData];
                    return YES;
                }];
                [rows addObject:size];
            }
            int selection = GetSelection(ScrubberSizeKey);
            NSUInteger index = selection / 5;
            YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:title pickerSectionTitle:nil rows:rows selectedItemIndex:index parentResponder:[self parentResponder]];
            [settingsViewController pushViewController:picker];
            return YES;
        }];
    [sectionItems addObject:scrubberSize];

    // Animated slider and scrubber
    YTSettingsSectionItem *animated = [YTSettingsSectionItemClass switchItemWithTitle:LOC(@"ANIMATED_SLIDER")
        titleDescription:LOC(@"ANIMATED_SLIDER_DESC")
        accessibilityIdentifier:nil
        switchOn:IsEnabled(AnimatedSliderKey)
        switchBlock:^BOOL (YTSettingsCell *cell, BOOL enabled) {
            [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:AnimatedSliderKey];
            return YES;
        }
        settingItemId:0];
    [sectionItems addObject:animated];

    if ([settingsViewController respondsToSelector:@selector(setSectionItems:forCategory:title:icon:titleDescription:headerHidden:)]) {
        YTIIcon *icon = [%c(YTIIcon) new];
        icon.iconType = YT_PLAY_CIRCLE;
        [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:TweakName icon:icon titleDescription:nil headerHidden:NO];
    } else
        [settingsViewController setSectionItems:sectionItems forCategory:TweakSection title:TweakName titleDescription:nil headerHidden:NO];
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == TweakSection) {
        [self updateYouSliderSectionWithEntry:entry];
        return;
    }
    %orig;
}

%end
