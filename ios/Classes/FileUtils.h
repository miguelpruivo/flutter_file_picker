//
//  FileUtils.h
//  Pods
//
//  Created by Miguel Ruivo on 05/12/2018.
//
@interface FileUtils : NSObject 
+ (NSString*) resolveType:(NSString*)type;
+ (NSString*) resolvePath:(NSArray<NSURL *> *)urls;
@end



