//
//  ImageUtils.h
//  Pods
//
//  Created by Miguel Ruivo on 05/03/2019.
//

@interface ImageUtils : NSObject
+ (BOOL)hasAlpha:(UIImage *)image;
+ (NSURL*)saveTmpImage:(UIImage *)image;
+ (NSDictionary *)getMetaDataFromImageData:(NSData *)imageData;
+ (NSData *)imageFromImage:(NSData *)imageData withMetaData:(NSDictionary *)metadata;
@end
