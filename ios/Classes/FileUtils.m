//
//  FileUtils.m
//  file_picker
//
//  Created by Miguel Ruivo on 05/12/2018.
//

#import "FileUtils.h"

@implementation FileUtils

+ (NSArray<NSString*> *) resolveType:(NSString*)type withAllowedExtensions:(NSArray<NSString*>*) allowedExtensions {
    
    if ([type isEqualToString:@"ANY"]) {
        return @[@"public.item"];
    } else if ([type isEqualToString:@"IMAGE"]) {
        return @[@"public.image"];
    } else if ([type isEqualToString:@"VIDEO"]) {
        return @[@"public.movie"];
    } else if ([type isEqualToString:@"AUDIO"]) {
        return @[@"public.audio"];
    } else if ([type isEqualToString:@"CUSTOM"]) {
        if(allowedExtensions == (id)[NSNull null] || allowedExtensions.count == 0) {
            return nil;
        }
        
        NSMutableArray<NSString*>* utis = [[NSMutableArray<NSString*> alloc] init];
        
        for(int i = 0 ; i<allowedExtensions.count ; i++){
            NSString * format = [NSString stringWithFormat:@"dummy.%@", allowedExtensions[i]];
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[format pathExtension], NULL);
            NSString * UTIString = (__bridge NSString *)(UTI);
            CFRelease(UTI);
            if([UTIString containsString:@"dyn."]){
                Log(@"[Skipping type] Unsupported file type: %@", UTIString);
                continue;
            } else{
                Log(@"Custom file type supported: %@", UTIString);
                [utis addObject: UTIString];
            }
        }
        return utis;
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

+ (int)countRemoteAssets:(NSArray<PHAsset*> *)assets {
    int total = 0;
    for(PHAsset * asset in assets) {
        NSArray *resourceArray = [PHAssetResource assetResourcesForAsset:asset];
        if(![[resourceArray.firstObject valueForKey:@"locallyAvailable"] boolValue]) {
            total++;
        }
    }
    return total;
}

+ (BOOL)isLocalAsset:(PHAsset *) asset {
    NSArray *resourceArray = [PHAssetResource assetResourcesForAsset:asset];
    return [[resourceArray.firstObject valueForKey:@"locallyAvailable"] boolValue];
}

@end
