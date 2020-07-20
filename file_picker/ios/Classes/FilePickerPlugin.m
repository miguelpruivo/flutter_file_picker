#import "FilePickerPlugin.h"
#import "FileUtils.h"
#import "ImageUtils.h"

@import DKImagePickerController;

@interface FilePickerPlugin() <UIImagePickerControllerDelegate, MPMediaPickerControllerDelegate, DKImageAssetExporterObserver>
@property (nonatomic) FlutterResult result;
@property (nonatomic) FlutterEventSink eventSink;
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
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:@"miguelruivo.flutter.plugins.filepickerevent"
                                         binaryMessenger:[registrar messenger]];
    
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    FilePickerPlugin* instance = [[FilePickerPlugin alloc] initWithViewController:viewController];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    [eventChannel setStreamHandler:instance];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if(self) {
        self.viewController = viewController;
    }
    
    return self;
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
        [self resolvePickDocumentWithMultiPick:NO pickDirectory:YES];
        return;
    }
    
    NSDictionary * arguments = call.arguments;
    BOOL isMultiplePick = ((NSNumber*)[arguments valueForKey:@"allowMultipleSelection"]).boolValue;
    if([call.method isEqualToString:@"any"] || [call.method containsString:@"custom"]) {
        self.allowedExtensions = [FileUtils resolveType:call.method withAllowedExtensions: [arguments valueForKey:@"allowedExtensions"]];
        if(self.allowedExtensions == nil) {
            _result([FlutterError errorWithCode:@"Unsupported file extension"
                                        message:@"If you are providing extension filters make sure that you are only using FileType.custom and the extension are provided without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension. If the problem persists, you may want to consider using FileType.all instead."
                                        details:nil]);
            _result = nil;
        } else if(self.allowedExtensions != nil) {
            [self resolvePickDocumentWithMultiPick:isMultiplePick pickDirectory:NO];
        }
    } else if([call.method isEqualToString:@"video"] || [call.method isEqualToString:@"image"] || [call.method isEqualToString:@"media"]) {
        [self resolvePickMedia:[FileUtils resolveMediaType:call.method] withMultiPick:isMultiplePick withCompressionAllowed:[arguments valueForKey:@"allowCompression"]];
    } else if([call.method isEqualToString:@"audio"]) {
        [self resolvePickAudio];
    } else {
        result(FlutterMethodNotImplemented);
        _result = nil;
    }
    
}

#pragma mark - Resolvers
- (void)resolvePickDocumentWithMultiPick:(BOOL)allowsMultipleSelection pickDirectory:(BOOL)isDirectory {
    
    @try{
        self.documentPickerController = [[UIDocumentPickerViewController alloc]
                                         initWithDocumentTypes: isDirectory ? @[@"public.folder"] : self.allowedExtensions
                                         inMode: isDirectory ? UIDocumentPickerModeOpen : UIDocumentPickerModeImport];
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

- (void) resolvePickMedia:(MediaType)type withMultiPick:(BOOL)multiPick withCompressionAllowed:(BOOL)allowCompression  {
    
    if(multiPick) {
        [self resolveMultiPickFromGallery:type withCompressionAllowed:allowCompression];
        return;
    }
    
    NSArray<NSString*> * videoTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    NSArray<NSString*> * imageTypes = @[(NSString *)kUTTypeImage];
    
    self.galleryPickerController = [[UIImagePickerController alloc] init];
    self.galleryPickerController.delegate = self;
    self.galleryPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.galleryPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    switch (type) {
        case IMAGE:
            self.galleryPickerController.mediaTypes = imageTypes;
            if (@available(iOS 11.0, *)) {
                self.galleryPickerController.imageExportPreset = allowCompression ? UIImagePickerControllerImageURLExportPresetCompatible : UIImagePickerControllerImageURLExportPresetCurrent;
            }
            break;
            
        case VIDEO:
            self.galleryPickerController.mediaTypes = videoTypes;
            if (@available(iOS 11.0, *)) {
                self.galleryPickerController.videoExportPreset = allowCompression ? AVAssetExportPresetHighestQuality : AVAssetExportPresetPassthrough;
            }
            break;
            
        default:
            self.galleryPickerController.mediaTypes = [videoTypes arrayByAddingObjectsFromArray:imageTypes];
            break;
    }
    
    [self.viewController presentViewController:self.galleryPickerController animated:YES completion:nil];
}

- (void) resolveMultiPickFromGallery:(MediaType)type withCompressionAllowed:(BOOL)allowCompression {
    DKImagePickerController * dkImagePickerController = [[DKImagePickerController alloc] init];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    if(_eventSink == nil) {
        // Create alert dialog for asset caching
        [alert.view setCenter: _viewController.view.center];
        [alert.view addConstraint: [NSLayoutConstraint constraintWithItem:alert.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:100]];
        
        // Create a default loader if user don't provide a status handler
        indicator.hidesWhenStopped = YES;
        [indicator setCenter: alert.view.center];
        indicator.autoresizingMask = (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin);
        [alert.view addSubview: indicator];
    }
    
    if (@available(iOS 11.0, *)) {
        DKImageAssetExporterConfiguration * exportConfiguration = [[DKImageAssetExporterConfiguration alloc] init];
        exportConfiguration.imageExportPreset = allowCompression ? UIImagePickerControllerImageURLExportPresetCompatible : UIImagePickerControllerImageURLExportPresetCurrent;
        exportConfiguration.videoExportPreset = allowCompression ? AVAssetExportPresetHighestQuality : AVAssetExportPresetPassthrough;
        dkImagePickerController.exporter = [dkImagePickerController.exporter initWithConfiguration:exportConfiguration];
    }
    
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
                [self->_viewController showViewController:alert sender:nil];
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
        NSMutableArray<NSString*>* paths = [[NSMutableArray<NSString*> alloc] init];
        
        for(DKAsset * asset in DKAssets){
            [paths addObject:asset.localTemporaryPath.path];
        }
        
        self->_result([paths count] > 0 ? paths : nil);
        self->_result = nil;
    }];
    
    [_viewController presentViewController:dkImagePickerController animated:YES completion:nil];
}

- (void) resolvePickAudio {
    
    self.audioPickerController = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    self.audioPickerController.delegate = self;
    self.audioPickerController.showsCloudItems = NO;
    self.audioPickerController.allowsPickingMultipleItems = NO;
    self.audioPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self.viewController presentViewController:self.audioPickerController animated:YES completion:nil];
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

#pragma mark - Alert dialog


@end
