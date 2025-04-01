#import "FilePickerPlugin.h"
#import "FileUtils.h"
#import "ImageUtils.h"
#import <Flutter/Flutter.h>

#ifdef PICKER_MEDIA
@import DKImagePickerController;

@interface FilePickerPlugin() <DKImageAssetExporterObserver>
#else
@interface FilePickerPlugin()
#endif
@property (nonatomic) FlutterResult result;
@property (nonatomic) FlutterEventSink eventSink;
#ifdef PICKER_MEDIA
@property (nonatomic) UIImagePickerController *galleryPickerController;
#endif
#ifdef PICKER_DOCUMENT
@property (nonatomic) UIDocumentPickerViewController *documentPickerController;
@property (nonatomic) UIDocumentInteractionController *interactionController;
#endif
@property (nonatomic) MPMediaPickerController *audioPickerController;
@property (nonatomic) NSArray<NSString *> * allowedExtensions;
@property (nonatomic) BOOL loadDataToMemory;
@property (nonatomic) int compressionQuality;
@property (nonatomic) BOOL allowCompression;
@property (nonatomic) dispatch_group_t group;
@property (nonatomic) MediaType type;
@property (nonatomic) BOOL isSaveFile;
@end

@implementation FilePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"miguelruivo.flutter.plugins.filepicker"
                                     binaryMessenger:[registrar messenger]];
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:@"miguelruivo.flutter.plugins.filepickerevent"
                                         binaryMessenger:[registrar messenger]];
    
    FilePickerPlugin* instance = [[FilePickerPlugin alloc] init];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    [eventChannel setStreamHandler:instance];
}

- (instancetype)init {
    self = [super init];
    
    return self;
}

- (UIViewController *)viewControllerWithWindow:(UIWindow *)window {
    UIWindow *windowToUse = window;
    if (windowToUse == nil) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                windowToUse = window;
                break;
            }
        }
    }
    
    UIViewController *topController = windowToUse.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    _eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
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
    
    if([call.method isEqualToString:@"clear"]) {
        _result([NSNumber numberWithBool: [FileUtils clearTemporaryFiles]]);
        _result = nil;
        return;
    }
    
    if([call.method isEqualToString:@"dir"]) {
        if (@available(iOS 13, *)) {
#ifdef PICKER_DOCUMENT
            [self resolvePickDocumentWithMultiPick:NO pickDirectory:YES];
#else
            _result([FlutterError errorWithCode:@"Unsupported picker type"
                                        message:@"Support for the Document picker is not compiled in. Remove the Pod::PICKER_DOCUMENT=false statement from your Podfile."
                                        details:nil]);
#endif
        } else {
            _result([self getDocumentDirectory]);
            _result = nil;
        }
        return;
    }
    
    NSDictionary * arguments = call.arguments;
    BOOL isMultiplePick = ((NSNumber*)[arguments valueForKey:@"allowMultipleSelection"]).boolValue;

    int compressionQuality = [[arguments valueForKey:@"compressionQuality"] intValue];
    self.allowCompression = self.compressionQuality > 0;
    self.loadDataToMemory = ((NSNumber*)[arguments valueForKey:@"withData"]).boolValue;
    
    if([call.method isEqualToString:@"any"] || [call.method containsString:@"custom"]) {
        self.allowedExtensions = [FileUtils resolveType:call.method withAllowedExtensions: [arguments valueForKey:@"allowedExtensions"]];
        if(self.allowedExtensions == nil) {
            _result([FlutterError errorWithCode:@"Unsupported file extension"
                                        message:@"If you are providing extension filters make sure that you are only using FileType.custom and the extension are provided without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension. If the problem persists, you may want to consider using FileType.any instead."
                                        details:nil]);
            _result = nil;
        } else if(self.allowedExtensions != nil) {
#ifdef PICKER_DOCUMENT
            [self resolvePickDocumentWithMultiPick:isMultiplePick pickDirectory:NO];
#else
            _result([FlutterError errorWithCode:@"Unsupported picker type"
                                        message:@"Support for the Document picker is not compiled in. Remove the Pod::PICKER_DOCUMENT=false statement from your Podfile."
                                        details:nil]);
#endif
        }
    } else if([call.method isEqualToString:@"video"] || [call.method isEqualToString:@"image"] || [call.method isEqualToString:@"media"]) {
#ifdef PICKER_MEDIA
        [self resolvePickMedia:[FileUtils resolveMediaType:call.method] withMultiPick:isMultiplePick withCompressionAllowed:self.allowCompression];
#else
        _result([FlutterError errorWithCode:@"Unsupported picker type"
                                    message:@"Support for the Media picker is not compiled in. Remove the Pod::PICKER_MEDIA=false statement from your Podfile."
                                    details:nil]);
#endif
    } else if([call.method isEqualToString:@"audio"]) {
 #ifdef PICKER_AUDIO
       [self resolvePickAudioWithMultiPick: isMultiplePick];
 #else
        _result([FlutterError errorWithCode:@"Unsupported picker type"
                                    message:@"Support for the Audio picker is not compiled in. Remove the Pod::PICKER_AUDIO=false statement from your Podfile."
                                    details:nil]);
#endif      
    } else if([call.method isEqualToString:@"save"]) {
#ifdef PICKER_DOCUMENT
        NSString *fileName = [arguments valueForKey:@"fileName"];
        NSString *fileType = [arguments valueForKey:@"fileType"];
        NSString *initialDirectory = [arguments valueForKey:@"initialDirectory"];
        FlutterStandardTypedData *bytes = [arguments valueForKey:@"bytes"];
        [self saveFileWithName:fileName fileType:fileType initialDirectory:initialDirectory bytes: bytes];
#else
        _result([FlutterError errorWithCode:@"Unsupported function"
                                    message:@"The save function requires the document picker to be compiled in. Remove the Pod::PICKER_DOCUMENT=false statement from your Podfile."
                                    details:nil]);
#endif
    } else {
        result(FlutterMethodNotImplemented);
        _result = nil;
    }
}

- (NSString*)getDocumentDirectory {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

#pragma mark - Resolvers

#ifdef PICKER_DOCUMENT
- (void)saveFileWithName:(NSString*)fileName fileType:(NSString *)fileType initialDirectory:(NSString*)initialDirectory bytes:(FlutterStandardTypedData*)bytes{
    self.isSaveFile = YES;
    NSFileManager* fm = [NSFileManager defaultManager];
    NSURL* documentsDirectory = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    NSURL* destinationPath = [documentsDirectory URLByAppendingPathComponent:fileName];
    NSError* error;
    if ([fm fileExistsAtPath:destinationPath.path]) {
        [fm removeItemAtURL:destinationPath error:&error];
        if (error != nil) {
            _result([FlutterError errorWithCode:@"Failed to remove file" message:[error debugDescription] details:nil]);
            error = nil;
        }
    }
    if(bytes != nil){
        [bytes.data writeToURL:destinationPath options:NSDataWritingAtomic error:&error];
        if (error != nil) {
            _result([FlutterError errorWithCode:@"Failed to write file" message:[error debugDescription] details:nil]);
            error = nil;
        }
    }
    self.documentPickerController = [[UIDocumentPickerViewController alloc] initWithURL:destinationPath inMode:UIDocumentPickerModeExportToService];
    self.documentPickerController.delegate = self;
    self.documentPickerController.presentationController.delegate = self;
    if(@available(iOS 13, *)){
       if(![[NSNull null] isEqual:initialDirectory] && ![@"" isEqualToString:initialDirectory]){
            self.documentPickerController.directoryURL = [NSURL URLWithString:initialDirectory];
        }
    }
    [[self viewControllerWithWindow:nil] presentViewController:self.documentPickerController animated:YES completion:nil];
}
#endif // PICKER_DOCUMENT

#ifdef PICKER_DOCUMENT
- (void)resolvePickDocumentWithMultiPick:(BOOL)allowsMultipleSelection pickDirectory:(BOOL)isDirectory {
    self.isSaveFile = NO;
    @try{
        self.documentPickerController = [[UIDocumentPickerViewController alloc]
                                         initWithDocumentTypes: isDirectory ? @[@"public.folder"] : self.allowedExtensions
                                         inMode: isDirectory ? UIDocumentPickerModeOpen : UIDocumentPickerModeImport];
    } @catch (NSException * e) {
        Log(@"Couldn't launch documents file picker. Probably due to iOS version being below 11.0 and not having the iCloud entitlement. If so, just make sure to enable it for your app in Xcode. Exception was: %@", e);
        _result = nil;
        return;
    }
    
    self.documentPickerController.allowsMultipleSelection = allowsMultipleSelection;    
    self.documentPickerController.delegate = self;
    self.documentPickerController.presentationController.delegate = self;
    
    [[self viewControllerWithWindow:nil] presentViewController:self.documentPickerController animated:YES completion:nil];
}
#endif // PICKER_DOCUMENT

#ifdef PICKER_MEDIA
- (void) resolvePickMedia:(MediaType)type withMultiPick:(BOOL)multiPick withCompressionAllowed:(BOOL)allowCompression  {

    self.type = type;
    
#ifdef PHPicker
    if (@available(iOS 14, *)) {
        PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
        config.filter = type == IMAGE ? [PHPickerFilter imagesFilter] : type == VIDEO ? [PHPickerFilter videosFilter] : [PHPickerFilter anyFilterMatchingSubfilters:@[[PHPickerFilter videosFilter], [PHPickerFilter imagesFilter]]];
        config.preferredAssetRepresentationMode = self.allowCompression ? PHPickerConfigurationAssetRepresentationModeCompatible : PHPickerConfigurationAssetRepresentationModeCurrent;
        
        if(multiPick) {
            config.selectionLimit = 0;
        }
        
        PHPickerViewController *pickerViewController = [[PHPickerViewController alloc] initWithConfiguration:config];
        pickerViewController.delegate = self;
        pickerViewController.presentationController.delegate = self;
        [[self viewControllerWithWindow:nil] presentViewController:pickerViewController animated:YES completion:nil];
        return;
    }
#endif
    
    if(multiPick) {
        [self resolveMultiPickFromGallery:type withCompressionAllowed:allowCompression];
        return;
    }
    
    NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    NSArray<NSString*> * imageTypes = @[(NSString *)kUTTypeImage];
    
    self.galleryPickerController = [[UIImagePickerController alloc] init];
    self.galleryPickerController.delegate = self;
    self.galleryPickerController.presentationController.delegate = self;
    self.galleryPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    switch (type) {
        case IMAGE:
            self.galleryPickerController.mediaTypes = imageTypes;
            self.galleryPickerController.imageExportPreset = allowCompression ? UIImagePickerControllerImageURLExportPresetCompatible : UIImagePickerControllerImageURLExportPresetCurrent;
            break;
            
        case VIDEO:
            self.galleryPickerController.mediaTypes = videoTypes;
            self.galleryPickerController.videoExportPreset = allowCompression ? AVAssetExportPresetHighestQuality : AVAssetExportPresetPassthrough;
            break;
            
        default:
            self.galleryPickerController.mediaTypes = [videoTypes arrayByAddingObjectsFromArray:imageTypes];
            break;
    }
    
    [[self viewControllerWithWindow:nil] presentViewController:self.galleryPickerController animated:YES completion:nil];
    
    
}

- (void) resolveMultiPickFromGallery:(MediaType)type withCompressionAllowed:(BOOL)allowCompression {
    DKImagePickerController * dkImagePickerController = [[DKImagePickerController alloc] init];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    UIViewController *currentViewController = [self viewControllerWithWindow:nil];
    if(_eventSink == nil) {
        // Create alert dialog for asset caching
        [alert.view setCenter: currentViewController.view.center];
        [alert.view addConstraint: [NSLayoutConstraint constraintWithItem:alert.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
        
        // Create a default loader if user don't provide a status handler
        indicator.hidesWhenStopped = YES;
        [indicator setCenter: alert.view.center];
        indicator.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
        [alert.view addSubview: indicator];
    }
    
    DKImageAssetExporterConfiguration * exportConfiguration = [[DKImageAssetExporterConfiguration alloc] init];
    exportConfiguration.imageExportPreset = allowCompression ? DKImageExportPresentCompatible : DKImageExportPresentCurrent;
    exportConfiguration.videoExportPreset = allowCompression ? AVAssetExportPresetHighestQuality : AVAssetExportPresetPassthrough;
    dkImagePickerController.exporter = [dkImagePickerController.exporter initWithConfiguration:exportConfiguration];
    
    dkImagePickerController.exportsWhenCompleted = YES;
    dkImagePickerController.showsCancelButton = YES;
    dkImagePickerController.sourceType = DKImagePickerControllerSourceTypePhoto;
    dkImagePickerController.assetType = type == VIDEO ? DKImagePickerControllerAssetTypeAllVideos : type == IMAGE ? DKImagePickerControllerAssetTypeAllPhotos : DKImagePickerControllerAssetTypeAllAssets;
    
    // Export status changed
    [dkImagePickerController setExportStatusChanged:^(enum DKImagePickerControllerExportStatus status) {
        
        if(status == DKImagePickerControllerExportStatusExporting && dkImagePickerController.selectedAssets.count > 0){
            Log("Exporting assets, this operation may take a while if remote (iCloud) assets are being cached.");
            
            if(self->_eventSink != nil){
                self->_eventSink([NSNumber numberWithBool:YES]);
            } else {
                [indicator startAnimating];
                [currentViewController showViewController:alert sender:nil];
            }
            
        } else {
            if(self->_eventSink != nil) {
                self->_eventSink([NSNumber numberWithBool:NO]);
            } else {
                [indicator stopAnimating];
                [alert dismissViewControllerAnimated:YES completion:nil];
            }
            
        }
    }];
    
    // Did cancel
    [dkImagePickerController setDidCancel:^(){
        self->_result(nil);
        self->_result = nil;
    }];
    
    // Did select
    [dkImagePickerController setDidSelectAssets:^(NSArray<DKAsset*> * __nonnull DKAssets) {
        NSMutableArray<NSURL*>* paths = [[NSMutableArray<NSURL*> alloc] init];
        
        for(DKAsset * asset in DKAssets) {
            if(asset.localTemporaryPath.absoluteURL != nil) {
                [paths addObject:asset.localTemporaryPath.absoluteURL];
            }
        }
        
        [self handleResult: paths];
    }];
    
    [[self viewControllerWithWindow:nil] presentViewController:dkImagePickerController animated:YES completion:nil];
}
#endif // PICKER_MEDIA

#ifdef PICKER_AUDIO
- (void) resolvePickAudioWithMultiPick:(BOOL)isMultiPick {
    
    
    self.audioPickerController = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    self.audioPickerController.delegate = self;
    self.audioPickerController.presentationController.delegate = self;
    self.audioPickerController.showsCloudItems = YES;
    self.audioPickerController.allowsPickingMultipleItems = isMultiPick;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if([self viewControllerWithWindow:nil].presentedViewController == nil){
            Log("Exporting assets, this operation may take a while if remote (iCloud) assets are being cached.");
        }
    });

    
    [[self viewControllerWithWindow:nil] presentViewController:self.audioPickerController animated:YES completion:nil];
}
#endif // PICKER_AUDIO


- (void) handleResult:(id) files {
    _result([FileUtils resolveFileInfo: [files isKindOfClass: [NSArray class]] ? files : @[files] withData:self.loadDataToMemory]);
    _result = nil;
}

#pragma mark - Delegates

#ifdef PICKER_DOCUMENT
// DocumentPicker delegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    
    if(_result == nil) {
        return;
    }
    if(self.isSaveFile){
        _result(urls[0].path);
        _result = nil;
        return;
    }
    NSMutableArray<NSURL *> *newUrls;
    if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
        newUrls = urls;
    }
    if(controller.documentPickerMode == UIDocumentPickerModeImport) {
        newUrls = [NSMutableArray new];
        for (NSURL *url in urls) {
            // Create file URL to temporary folder
            NSURL *tempURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
            // Append filename (name+extension) to URL
            tempURL = [tempURL URLByAppendingPathComponent:url.lastPathComponent];
            NSError *error;
            // If file with same name exists remove it (replace file with new one)
            if ([[NSFileManager defaultManager] fileExistsAtPath:tempURL.path]) {
                [[NSFileManager defaultManager] removeItemAtPath:tempURL.path error:&error];
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
            }
            // Move file from app_id-Inbox to tmp/filename
            [[NSFileManager defaultManager] moveItemAtPath:url.path toPath:tempURL.path error:&error];
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            } else {
                [newUrls addObject:tempURL];
            }
        }
    }
    
    [self.documentPickerController dismissViewControllerAnimated:YES completion:nil];
    
    if(controller.documentPickerMode == UIDocumentPickerModeOpen) {
        _result([newUrls objectAtIndex:0].path);
        _result = nil;
        return;
    }
    
    [self handleResult: newUrls];
}
#endif // PICKER_DOCUMENT

#ifdef PICKER_MEDIA
// ImagePicker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if(_result == nil) {
        return;
    }
    
    NSURL *pickedVideoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    NSURL *pickedImageUrl;

    if(@available(iOS 13.0, *)) {

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

    } else {
        pickedImageUrl = [info objectForKey:UIImagePickerControllerImageURL];
    }

    [picker dismissViewControllerAnimated:YES completion:NULL];

    if(pickedImageUrl == nil && pickedVideoUrl == nil) {
        _result([FlutterError errorWithCode:@"file_picker_error"
                                    message:@"Temporary file could not be created"
                                    details:nil]);
        _result = nil;
        return;
    }

    [self handleResult: pickedVideoUrl != nil ? pickedVideoUrl : pickedImageUrl];
}

#ifdef PHPicker

-(void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)){
    if(_result == nil) {
        return;
    }

    Log(@"Picker:%@ didFinishPicking:%@", picker, results);
    [picker dismissViewControllerAnimated:YES completion:nil];

    if(results.count == 0) {
        Log(@"FilePicker canceled");
        _result(nil);
        _result = nil;
        return;
    }

    NSMutableArray<NSURL *> * urls = [[NSMutableArray alloc] init];
    NSMutableArray<NSString *> * errors = [[NSMutableArray alloc] init];
    
    self.group = dispatch_group_create();
    
    // Create image directory if it doesn't exist
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *imagesDir = [documentsPath stringByAppendingPathComponent:@"picked_images"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:imagesDir]) {
        NSError *dirError;
        [fileManager createDirectoryAtPath:imagesDir withIntermediateDirectories:YES attributes:nil error:&dirError];
        if (dirError) {
            Log(@"Failed to create image directory: %@", dirError);
        }
    }

    if(self->_eventSink != nil) {
        self->_eventSink([NSNumber numberWithBool:YES]);
    }

    // Process images sequentially to avoid memory spikes
    dispatch_queue_t processQueue = dispatch_queue_create("com.filepicker.imageprocessing", DISPATCH_QUEUE_SERIAL);
    __block NSInteger completedCount = 0;
    NSInteger totalCount = results.count;

    bool isImageSelection = self.type == IMAGE;
    bool isMediaSelection = self.type == MEDIA;
    for (NSInteger index = 0; index < results.count; ++index) {
        dispatch_group_enter(_group);
        PHPickerResult * result = [results objectAtIndex:index];
        
        dispatch_async(processQueue, ^{
            @autoreleasepool {
            if (isMediaSelection) {
                if (![result.itemProvider hasItemConformingToTypeIdentifier:@"public.image"] &&
                    ![result.itemProvider hasItemConformingToTypeIdentifier:@"public.movie"]) {
                    [errors addObject:[NSString stringWithFormat:@"Item at index %ld is not an image or video", (long)index]];
                    dispatch_group_leave(self->_group);
                    return;
                }
            } else if (isImageSelection) {
                if (![result.itemProvider hasItemConformingToTypeIdentifier:@"public.image"]) {
                    [errors addObject:[NSString stringWithFormat:@"Item at index %ld is not an image", (long)index]];
                    dispatch_group_leave(self->_group);
                    return;
                }
            }

            NSString *typeIdentifier;
            if ([result.itemProvider hasItemConformingToTypeIdentifier:@"public.image"]) {
                typeIdentifier = @"public.image";
            } else {
                typeIdentifier = @"public.movie";
            }
               
               [result.itemProvider loadFileRepresentationForTypeIdentifier:typeIdentifier completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
                    @autoreleasepool {
                        if (error != nil || url == nil) {
                            [errors addObject:[NSString stringWithFormat:@"Failed to load image at index %ld: %@",
                                (long)index, error ? error.localizedDescription : @"Unknown error"]];
                            dispatch_group_leave(self->_group);
                            return;
                        }

                        @try {
                            // Create unique filename in app_images directory
                            NSString *filename = [NSString stringWithFormat:@"image_%@_%ld.%@",
                                [[NSUUID UUID] UUIDString],
                                (long)[[NSDate date] timeIntervalSince1970],
                                url.pathExtension.length > 0 ? url.pathExtension : @"jpg"];
                            
                            NSString *destinationPath = [imagesDir stringByAppendingPathComponent:filename];
                            NSURL *destinationUrl = [NSURL fileURLWithPath:destinationPath];
                            
                            // Load image data with options to reduce memory usage
                            NSError *loadError = nil;
                            NSData *imageData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&loadError];
                            
                            if (loadError || !imageData) {
                                [errors addObject:[NSString stringWithFormat:@"Failed to load image data at index %ld: %@",
                                    (long)index, loadError.localizedDescription ?: @"Unknown error"]];
                            } else {
                                // Write to destination
                                if ([imageData writeToURL:destinationUrl options:NSDataWritingAtomic error:&loadError]) {
                                    [urls addObject:destinationUrl];
                                } else {
                                    [errors addObject:[NSString stringWithFormat:@"Failed to save image at index %ld: %@",
                                        (long)index, loadError.localizedDescription]];
                                }
                            }
                            
                            // Clean up
                            imageData = nil;
                            
                        } @catch (NSException *exception) {
                            [errors addObject:[NSString stringWithFormat:@"Exception processing image at index %ld: %@",
                                (long)index, exception.description]];
                        }
                        
                        // Update progress
                        completedCount++;
                        if(self->_eventSink != nil) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self->_eventSink(@{
                                    @"type": @"progress",
                                    @"count": @(completedCount),
                                    @"total": @(totalCount)
                                });
                            });
                        }
                        
                        dispatch_group_leave(self->_group);
                    }
                }];
            }
        });
    }

    dispatch_group_notify(_group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        self->_group = nil;
        
        if(self->_eventSink != nil) {
            self->_eventSink([NSNumber numberWithBool:NO]);
        }

        if (urls.count > 0) {
            // If we have at least one successful image, return the results
            if (errors.count > 0) {
                // Log errors but don't fail the operation
                Log(@"Some images failed to process: %@", [errors componentsJoinedByString:@", "]);
            }
            [self handleResult:urls];
        } else {
            // Only if all images failed, return an error
            self->_result([FlutterError errorWithCode:@"file_picker_error"
                                            message:@"Failed to process any images"
                                            details:[errors componentsJoinedByString:@"\n"]]);
        }
        self->_result = nil;
    });
}

#endif // PHPicker
#endif // PICKER_MEDIA

#ifdef PICKER_AUDIO
// AudioPicker delegate
- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [mediaPicker dismissViewControllerAnimated:YES completion:NULL];
    int numberOfItems = (int)[mediaItemCollection items].count;
    
    if(numberOfItems == 0) {
        return;
    }
    
    if(_eventSink != nil) {
        _eventSink([NSNumber numberWithBool:YES]);
    }
    
    NSMutableArray<NSURL *> * urls = [[NSMutableArray alloc] initWithCapacity:numberOfItems];
    
    for(MPMediaItemCollection * item in [mediaItemCollection items]) {
        NSURL * cachedAsset = [FileUtils exportMusicAsset: [item valueForKey:MPMediaItemPropertyAssetURL] withName: [item valueForKey:MPMediaItemPropertyTitle]];
        [urls addObject: cachedAsset];
    }
    
    if(_eventSink != nil) {
        _eventSink([NSNumber numberWithBool:NO]);
    }
    
    if(urls.count == 0) {
        Log(@"Couldn't retrieve the audio file path, either is not locally downloaded or the file is DRM protected.");
    }
    [self handleResult:urls];
}
#endif // PICKER_AUDIO

#pragma mark - Actions canceled

#ifdef PICKER_MEDIA
- (void)presentationControllerDidDismiss:(UIPresentationController *)controller {
    Log(@"FilePicker canceled");
    if (self.result != nil) {
        self.result(nil);
        self.result = nil;
    }
}
#endif // PICKER_MEDIA

#ifdef PICKER_AUDIO
- (void)mediaPickerDidCancel:(MPMediaPickerController *)controller {
    Log(@"FilePicker canceled");
    _result(nil);
    _result = nil;
    [controller dismissViewControllerAnimated:YES completion:NULL];
}
#endif // PICKER_AUDIO

#ifdef PICKER_DOCUMENT
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    Log(@"FilePicker canceled");
    _result(nil);
    _result = nil;
    [controller dismissViewControllerAnimated:YES completion:NULL];
}
#endif // PICKER_DOCUMENT

#ifdef PICKER_MEDIA
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    Log(@"FilePicker canceled");
    _result(nil);
    _result = nil;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}
#endif

#pragma mark - Alert dialog


@end
