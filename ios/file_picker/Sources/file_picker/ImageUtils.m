//
//  ImageUtils.m
//  file_picker
//
//  Created by Miguel Ruivo on 05/03/2019.
//

#import "ImageUtils.h"
#import <UIKit/UIKit.h>

@implementation ImageUtils

// Returns true if the image has an alpha layer
+ (BOOL)hasAlpha:(UIImage *)image {
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
    return (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast);
}

// Temporarily save the image in the app's tmp directory.
+ (NSURL *)saveTmpImage:(UIImage *)image {
    BOOL hasAlpha = [ImageUtils hasAlpha:image];
    NSData *data = hasAlpha ? UIImagePNGRepresentation(image) : UIImageJPEGRepresentation(image, 1.0);
    NSString *fileExtension = hasAlpha ? @"tmp_%@.png" : @"tmp_%@.jpg";
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *tmpFile = [NSString stringWithFormat:fileExtension, guid];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *tmpPath = [tmpDirectory stringByAppendingPathComponent:tmpFile];
    
    if ([[NSFileManager defaultManager] createFileAtPath:tmpPath contents:data attributes:nil]) {
        return  [NSURL URLWithString: tmpPath];
    }
    return nil;
}

+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData {
  CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
  NSDictionary *metadata =
      (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
  CFRelease(source);
  return metadata;
}

+ (NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata {
  NSMutableData *targetData = [NSMutableData data];
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
  if (source == NULL) {
    return nil;
  }
  CGImageDestinationRef destination = NULL;
  CFStringRef sourceType = CGImageSourceGetType(source);
  if (sourceType != NULL) {
    destination =
        CGImageDestinationCreateWithData((__bridge CFMutableDataRef)targetData, sourceType, 1, nil);
  }
  if (destination == NULL) {
    CFRelease(source);
    return nil;
  }
  CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata);
  CGImageDestinationFinalize(destination);
  CFRelease(source);
  CFRelease(destination);
  return targetData;
}

@end
