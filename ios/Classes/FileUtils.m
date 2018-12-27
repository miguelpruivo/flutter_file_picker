//
//  FileUtils.m
//  file_picker
//
//  Created by Miguel Ruivo on 05/12/2018.
//

#import "FileUtils.h"

@implementation FileUtils

+ (NSString*) resolveType:(NSString*)type {
    
    BOOL isCustom = [type containsString:@"__CUSTOM_"];
    
    if(isCustom) {
        type = [type stringByReplacingOccurrencesOfString:@"__CUSTOM_" withString:@""];
        NSString * format = [NSString stringWithFormat:@"dummy.%@", type];
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[format pathExtension], NULL);
        NSString * UTIString = (__bridge NSString *)(UTI);
        CFRelease(UTI);
        NSLog(@"Custom file type: %@", UTIString);
        return [UTIString containsString:@"dyn."] ? nil : UTIString;
    }
    
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
