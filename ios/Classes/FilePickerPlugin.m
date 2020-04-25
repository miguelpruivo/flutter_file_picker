#import "FilePickerPlugin.h"
#import "FileUtils.h"
#import "ImageUtils.h"

@import BSImagePicker;

@interface FilePickerPlugin() <UIImagePickerControllerDelegate, MPMediaPickerControllerDelegate>
@property (nonatomic) FlutterResult result;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIImagePickerController *galleryPickerController;
@property (nonatomic) UIDocumentPickerViewController *documentPickerController;
@property (nonatomic) UIDocumentInteractionController *interactionController;
@property (nonatomic) MPMediaPickerController *audioPickerController;
@property (nonatomic) NSArray<NSString *> * allowedExtensions;
@end

@implementation FilePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"miguelruivo.flutter.plugins.filepicker"
                                     binaryMessenger:[registrar messenger]];
    
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    FilePickerPlugin* instance = [[FilePickerPlugin alloc] initWithViewController:viewController];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}


- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if(self) {
        self.viewController = viewController;
    }
    
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (_result) {
        result([FlutterError errorWithCode:@"multiple_request"
                                    message:@"Cancelled by a second request"
                                    details:nil]);
        _result = nil;
        return;
    }
    
    _result = result;
    NSDictionary * arguments = call.arguments;
    BOOL isMultiplePick = ((NSNumber*)[arguments valueForKey:@"allowMultipleSelection"]).boolValue;
    if((isMultiplePick && ![call.method isEqualToString:@"IMAGE"]) || [call.method isEqualToString:@"ANY"] || [call.method containsString:@"CUSTOM"]) {
        self.allowedExtensions = [FileUtils resolveType:call.method withAllowedExtensions: [arguments valueForKey:@"allowedExtensions"]];
        if(self.allowedExtensions == nil) {
            _result([FlutterError errorWithCode:@"Unsupported file extension"
                                        message:@"If you are providing extension filters make sure that you are only using FileType.custom and the extension are provided without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension. If the problem persists, you may want to consider using FileType.all instead."
                                        details:nil]);
            _result = nil;
        } else if(self.allowedExtensions != nil) {
            [self resolvePickDocumentWithMultipleSelection:isMultiplePick];
        }
    } else if([call.method isEqualToString:@"VIDEO"]) {
        [self resolvePickVideo];
    } else if([call.method isEqualToString:@"AUDIO"]) {
        [self resolvePickAudio];
    } else if([call.method isEqualToString:@"IMAGE"]) {
        [self resolvePickImage:isMultiplePick];
    } else {
        result(FlutterMethodNotImplemented);
        _result = nil;
    }
    
}

#pragma mark - Resolvers

- (void)resolvePickDocumentWithMultipleSelection:(BOOL)allowsMultipleSelection {
    
    @try{
        self.documentPickerController = [[UIDocumentPickerViewController alloc]
                             initWithDocumentTypes: self.allowedExtensions
                             inMode:UIDocumentPickerModeImport];
    } @catch (NSException * e) {
       Log(@"Couldn't launch documents file picker. Probably due to iOS version being below 11.0 and not having the iCloud entitlement. If so, just make sure to enable it for your app in Xcode. Exception was: %@", e);
        _result = nil;
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        self.documentPickerController.allowsMultipleSelection = allowsMultipleSelection;
    } else if(allowsMultipleSelection) {
       Log(@"Multiple file selection is only supported on iOS 11 and above. Single selection will be used.");
    }
    
    self.documentPickerController.delegate = self;
    self.documentPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.galleryPickerController.allowsEditing = NO;
    
    [_viewController presentViewController:self.documentPickerController animated:YES completion:nil];
}


- (void) resolvePickImage:(BOOL)withMultiPick {
    
    if(!withMultiPick) {
        self.galleryPickerController = [[UIImagePickerController alloc] init];
        self.galleryPickerController.delegate = self;
        self.galleryPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        self.galleryPickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        self.galleryPickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [_viewController presentViewController:self.galleryPickerController animated:YES completion:nil];
    } else {
        ImagePickerController * multiImagePickerController = [[ImagePickerController alloc] initWithSelectedAssets:@[]];
        
        UIProgressView * progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0, 0.0, multiImagePickerController.view.bounds.size.width, 10.0)];
        CGAffineTransform transform = CGAffineTransformMakeScale(1.0f, 4.0f);
        progressView.transform = transform;
            
        [_viewController presentImagePicker:multiImagePickerController
                                   animated:YES
                                     select:^(PHAsset * _Nonnull selectedAsset) {}
                                   deselect:^(PHAsset * _Nonnull deselectedAsset) {}
                                     cancel:^(NSArray<PHAsset *> * _Nonnull canceledAsset) {
            self->_result(nil);
            self->_result = nil;
        }
                                     finish:^(NSArray<PHAsset *> * _Nonnull assets) {
            int totalRemoteAssets = [FileUtils countRemoteAssets:assets];
            NSMutableArray<NSString*> *paths = [[NSMutableArray<NSString*> alloc] init];
            NSMutableDictionary<NSString*, NSNumber*> * progresses = [[NSMutableDictionary<NSString*, NSNumber*> alloc] initWithCapacity: totalRemoteAssets];
            
            if(totalRemoteAssets > 0) {
                [multiImagePickerController.view addSubview:progressView];
            }
            
            if(assets.count > 0) {
                dispatch_semaphore_t completer = dispatch_semaphore_create(0);
                __block int processedAssets = 0;
                
                for(PHAsset* asset in assets){
                    PHContentEditingInputRequestOptions * options = [[PHContentEditingInputRequestOptions alloc] init];
                    options.networkAccessAllowed = YES;
                    
                    if(![FileUtils isLocalAsset:asset]){
                        options.progressHandler = ^(double progress, BOOL * _Nonnull stop) {
                            progresses[asset.localIdentifier] = [NSNumber numberWithFloat:progress];
                            @synchronized(progresses){
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    progressView.progress = [[[progresses allValues] valueForKeyPath:@"@sum.self"] floatValue] / totalRemoteAssets;
                                });
                            };
                        };
                    }
                    
                    [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
                        NSURL *imageURL = contentEditingInput.fullSizeImageURL;
                        [paths addObject:imageURL.path];
                        
                        if(++processedAssets == assets.count) {
                            dispatch_semaphore_signal(completer);
                        }
                    }];
                }
                
                if (![NSThread isMainThread]) {
                    dispatch_semaphore_wait(completer, DISPATCH_TIME_FOREVER);
                } else {
                    while (dispatch_semaphore_wait(completer, DISPATCH_TIME_NOW)) {
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
                    }
                }
            }
            
            self->_result(paths);
            self->_result = nil;
            
        }  completion:^{}];
    }
}

- (void) resolvePickAudio {
    
    self.audioPickerController = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    self.audioPickerController.delegate = self;
    self.audioPickerController.showsCloudItems = NO;
    self.audioPickerController.allowsPickingMultipleItems = NO;
    self.audioPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self.viewController presentViewController:self.audioPickerController animated:YES completion:nil];
}

- (void) resolvePickVideo {
    
    self.galleryPickerController = [[UIImagePickerController alloc] init];
    self.galleryPickerController.delegate = self;
    self.galleryPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.galleryPickerController.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    self.galleryPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    [self.viewController presentViewController:self.galleryPickerController animated:YES completion:nil];
}

#pragma mark - Delegates

// DocumentPicker delegate - iOS 10 only
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url{
    [self.documentPickerController dismissViewControllerAnimated:YES completion:nil];
    NSString * path = (NSString *)[url path];
    _result(path);
    _result = nil;
}

// DocumentPicker delegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    
    if(_result == nil) {
        return;
    }
    
    [self.documentPickerController dismissViewControllerAnimated:YES completion:nil];
    NSArray * result = [FileUtils resolvePath:urls];
    
    if([result count] > 1) {
        _result(result);
    } else {
       _result([result objectAtIndex:0]);
    }
    _result = nil;
    
}


// ImagePicker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if(_result == nil) {
        return;
    }
    
    NSURL *pickedVideoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    NSURL *pickedImageUrl;
    
    if(@available(iOS 13.0, *)){
        
        if(pickedVideoUrl != nil) {
            NSString * fileName = [pickedVideoUrl lastPathComponent];
            NSURL * destination = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
            
            if([[NSFileManager defaultManager] isReadableFileAtPath: [pickedVideoUrl path]]) {
                Log(@"Caching video file for iOS 13 or above...");
                [[NSFileManager defaultManager] copyItemAtURL:pickedVideoUrl toURL:destination error:nil];
                pickedVideoUrl = destination;
            }
        } else {
            pickedImageUrl = [info objectForKey:UIImagePickerControllerImageURL];
        }
        
    } else if (@available(iOS 11.0, *)) {
       pickedImageUrl = [info objectForKey:UIImagePickerControllerImageURL];
    } else {
       UIImage *pickedImage  = [info objectForKey:UIImagePickerControllerEditedImage];
    
        if(pickedImage == nil) {
            pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        pickedImageUrl = [ImageUtils saveTmpImage:pickedImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:NULL];

    if(pickedImageUrl == nil && pickedVideoUrl == nil) {
        _result([FlutterError errorWithCode:@"file_picker_error"
                                    message:@"Temporary file could not be created"
                                    details:nil]);
        _result = nil;
        return;
    }
    
    _result([pickedVideoUrl != nil ? pickedVideoUrl : pickedImageUrl path]);
    _result = nil;
}


// AudioPicker delegate
- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [mediaPicker dismissViewControllerAnimated:YES completion:NULL];
    NSURL *url = [[[mediaItemCollection items] objectAtIndex:0] valueForKey:MPMediaItemPropertyAssetURL];
    if(url == nil) {
        Log(@"Couldn't retrieve the audio file path, either is not locally downloaded or the file is DRM protected.");
    }
     _result([url absoluteString]);
     _result = nil;
}

#pragma mark - Actions canceled

- (void)mediaPickerDidCancel:(MPMediaPickerController *)controller {
    Log(@"FilePicker canceled");
    _result(nil);
    _result = nil;
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    Log(@"FilePicker canceled");
    _result(nil);
    _result = nil;
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    Log(@"FilePicker canceled");
    _result(nil);
    _result = nil;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
