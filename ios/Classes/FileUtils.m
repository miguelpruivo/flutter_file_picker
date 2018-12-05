//
//  FileUtils.m
//  file_picker
//
//  Created by Miguel Ruivo on 05/12/2018.
//

#import "FileUtils.h"

@implementation FileUtils

+ (NSString*) resolveType:(NSString*)type {
    
    if ([type isEqualToString:@"PDF"]) {
        return @"com.adobe.pdf";
    }
    else if ([type isEqualToString:@"ANY"])  {
        return @"public.item";
    } else {
        return nil;
    }
}


+ (NSString*) resolvePath:(NSArray<NSURL *> *)urls{
    NSString * uri;
    
    for (NSURL *url in urls) {
        uri = (NSString *)[url path];
    }
    
    return uri;
}

@end
