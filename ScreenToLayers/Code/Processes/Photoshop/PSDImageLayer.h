
@import Foundation;
@import QuartzCore;
#import "PSDLayer.h"

@interface PSDImageLayer : PSDLayer

@property (nonatomic, strong, nullable) NSData *imageData;
@property (nonatomic, assign) CGRect rect;

@end
