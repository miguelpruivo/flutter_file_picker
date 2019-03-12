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
        Log(@"Custom file type: %@", UTIString);
        return [UTIString containsString:@"dyn."] ? nil : UTIString;
    }
    
    if ([type isEqualToString:@"ANY"]) {
        return @"public.item";
    } else if ([type isEqualToString:@"IMAGE"]) {
        return @"public.image";
    } else if ([type isEqualToString:@"VIDEO"]) {
        return @"public.movie";
    } else if ([type isEqualToString:@"AUDIO"]) {
        return @"public.audio";
    } else {
        return nil;
    }
}

+ (NSMutableArray*) resolvePath:(NSArray<NSURL *> *)urls{
    NSString * uri;
    NSMutableArray * paths = [[NSMutableArray alloc] init];
    
    for (NSURL *url in urls) {
        uri = (NSString *)[url path];
        [paths addObject:uri];
    }
    
    return paths;
}

@end
