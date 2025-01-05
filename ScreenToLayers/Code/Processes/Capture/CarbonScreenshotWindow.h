
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface CarbonScreenshotWindow : NSObject

#pragma mark Properties

@property (readwrite, strong, nullable) NSString *ownerName;
@property (readwrite, strong, nullable) NSString *title;
@property (readwrite) NSInteger processID;
@property (readwrite) CGWindowID windowID;
@property (readwrite) NSRect bounds;
@property (readwrite) NSInteger level;
@property (readwrite) NSInteger tag;

#pragma mark Window list

+ (NSArray<CarbonScreenshotWindow *> *)sharedWindows;

@end

NS_ASSUME_NONNULL_END
