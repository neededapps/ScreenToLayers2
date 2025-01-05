
#import "CarbonScreenshotWindow.h"

static
void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
    NSMutableArray *windows = (__bridge NSMutableArray *)context;
    int sharingState = [entry[(id)kCGWindowSharingState] intValue];
    if (sharingState == kCGWindowSharingNone) {
        return;
    }
    
    CarbonScreenshotWindow *window = [[CarbonScreenshotWindow alloc] init];
    window.processID = [entry[(id)kCGWindowOwnerPID] integerValue];
    window.windowID = [entry[(id)kCGWindowNumber] unsignedIntValue];
    window.level = [entry[(id)kCGWindowLayer] integerValue];
    window.ownerName = entry[(id)kCGWindowOwnerName];
    window.title = entry[(id)kCGWindowName];
    window.tag = windows.count;
    
    CGRect windowBounds;
    CFDictionaryRef boundsDict = (__bridge CFDictionaryRef)entry[(id)kCGWindowBounds];
    CGRectMakeWithDictionaryRepresentation(boundsDict, &windowBounds);
    window.bounds = windowBounds;
    [windows addObject:window];
}

@implementation CarbonScreenshotWindow

#pragma mark Window list

+ (NSArray<CarbonScreenshotWindow *> *)sharedWindows {
    CGWindowListOption listOptions = kCGWindowListOptionOnScreenOnly;
    CFArrayRef cfWindowList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);
    NSMutableArray<CarbonScreenshotWindow *> *grabbedWindows = [NSMutableArray array];
    CFArrayApplyFunction(cfWindowList,
                         CFRangeMake(0, CFArrayGetCount(cfWindowList)),
                         &WindowListApplierFunction,
                         (__bridge void *)(grabbedWindows));
    CFRelease(cfWindowList);
    return grabbedWindows;
}

@end
