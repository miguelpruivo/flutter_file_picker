//
//  FileUtils.h
//  Pods
//
//  Created by Miguel Ruivo on 05/12/2018.
//
#import <MobileCoreServices/MobileCoreServices.h>
@interface FileUtils : NSObject 
+ (NSString*) resolveType:(NSString*)type;
+ (NSString*) resolvePath:(NSArray<NSURL *> *)urls;
@end



