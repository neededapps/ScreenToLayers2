
@import AppKit;

@class MASShortcut, MASShortcutValidator;

extern NSString * _Nonnull const MASShortcutBinding;

typedef NS_ENUM(NSInteger, MASShortcutViewStyle) {
    MASShortcutViewStyleDefault = 0,  // Height = 19 px
    MASShortcutViewStyleTexturedRect, // Height = 25 px
    MASShortcutViewStyleRounded,      // Height = 43 px
    MASShortcutViewStyleFlat,
    MASShortcutViewStyleRegularSquare
};

@interface MASShortcutView : NSView

@property (nonatomic, strong, nullable) MASShortcut *shortcutValue;
@property (nonatomic, strong, nullable) MASShortcutValidator *shortcutValidator;
@property (nonatomic, getter = isRecording) BOOL recording;
@property (nonatomic, getter = isEnabled) BOOL enabled;
@property (nonatomic, copy, nullable) void (^shortcutValueChange)(MASShortcutView * _Nonnull sender);
@property (nonatomic, assign) MASShortcutViewStyle style;

@property(copy, nullable) NSString *associatedUserDefaultsKey;

/// Returns custom class for drawing control.
+ (nonnull Class)shortcutCellClass;

- (void)setAcceptsFirstResponder:(BOOL)value;

@end

/**
 A simplified interface to bind the recorder value to user defaults.

 You can bind the `shortcutValue` to user defaults using the standard
 `bind:toObject:withKeyPath:options:` call, but since that’s a lot to type
 and read, here’s a simpler option.

 Setting the `associatedUserDefaultsKey` binds the view’s shortcut value
 to the given user defaults key. You can supply a value transformer to convert
 values between user defaults and `MASShortcut`. If you don’t supply
 a transformer, the `NSUnarchiveFromDataTransformerName` will be used
 automatically.

 Set `associatedUserDefaultsKey` to `nil` to disconnect the binding.
*/
@interface MASShortcutView (Bindings)

@property(copy, nullable) NSString *associatedUserDefaultsKey;

@end
