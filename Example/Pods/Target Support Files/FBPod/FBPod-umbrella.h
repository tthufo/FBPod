#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "FB_Plugin.h"
#import "NSData+Base64.h"

FOUNDATION_EXPORT double FBPodVersionNumber;
FOUNDATION_EXPORT const unsigned char FBPodVersionString[];

