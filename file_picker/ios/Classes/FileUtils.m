//
//  FileUtils.m
//  file_picker
//
//  Created by Miguel Ruivo on 05/12/2018.
//

#import "FileUtils.h"
#import "FileInfo.h"

@implementation FileUtils

+ (BOOL) clearTemporaryFiles {
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *cacheFiles = [fileManager contentsOfDirectoryAtPath:tmpDirectory error:&error];
    
    for (NSString *file in cacheFiles) {
        error = nil;
        [fileManager removeItemAtPath:[tmpDirectory stringByAppendingPathComponent:file] error:&error];
        if(error != nil) {
            Log(@"Failed to remove temporary file %@, aborting. Error: %@", file, error);
            return false;
        }
    }
    Log(@"All temporary files clear");
    return true;
}

+ (NSArray<NSString*> *) resolveType:(NSString*)type withAllowedExtensions:(NSArray<NSString*>*) allowedExtensions {
    
    if ([type isEqualToString:@"any"]) {
        return @[@"public.item"];
    } else if ([type isEqualToString:@"image"]) {
        return @[@"public.image"];
    } else if ([type isEqualToString:@"video"]) {
        return @[@"public.movie"];
    } else if ([type isEqualToString:@"audio"]) {
        return @[@"public.audio"];
    } else if ([type isEqualToString:@"media"]) {
        return @[@"public.image", @"public.video"];
    } else if ([type isEqualToString:@"custom"]) {
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

+ (MediaType) resolveMediaType:(NSString *)type {
    if([type isEqualToString:@"video"]) {
        return VIDEO;
    } else if([type isEqualToString:@"image"]) {
        return IMAGE;
    } else {
        return MEDIA;
    }
}

+ (NSArray<NSDictionary *> *)resolveFileInfo:(NSArray<NSURL *> *)urls withData: (BOOL)loadData {
    
    if(urls == nil) {
        return nil;
    }
    
    NSMutableArray * files = [[NSMutableArray alloc] initWithCapacity:urls.count];
    
    for(NSURL * url in urls) {
        NSString * path = (NSString *)[url path];
        NSDictionary<NSFileAttributeKey, id> * fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        
        [files addObject: [[[FileInfo alloc] initWithPath: path
                                            andName: [[path lastPathComponent] stringByDeletingPathExtension]
                                            andSize: [NSNumber numberWithLongLong: [@(fileAttributes.fileSize) longLongValue] / 1024]
                                            andData: loadData ? [NSData dataWithContentsOfFile:path options: 0 error:nil] : nil] toData]];
    }
    
    return files;
}

@end
