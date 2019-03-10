#import "FilePickerPlugin.h"
#import "FileUtils.h"
#import "ImageUtils.h"

@interface FilePickerPlugin() <UIImagePickerControllerDelegate, MPMediaPickerControllerDelegate>
@property (nonatomic) FlutterResult result;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIImagePickerController *galleryPickerController;
@property (nonatomic) UIDocumentPickerViewController *pickerController;
@property (nonatomic) UIDocumentInteractionController *interactionController;
@property (nonatomic) MPMediaPickerController *audioPickerController;
@property (nonatomic) NSString * fileType;
@end

@implementation FilePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"file_picker"
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
        _result([FlutterError errorWithCode:@"multiple_request"
                                    message:@"Cancelled by a second request"
                                    details:nil]);
        _result = nil;
    }
    
    _result = result;
    
    
    if([call.method isEqualToString:@"VIDEO"]) {
        [self resolvePickVideo];
    }
    else if([call.method isEqualToString:@"AUDIO"]) {
        [self resolvePickAudio];
    }
    else if([call.method isEqualToString:@"IMAGE"]) {
        [self resolvePickImage];
    } else {
        self.fileType = [FileUtils resolveType:call.method];
        
        if(self.fileType == nil){
            result(FlutterMethodNotImplemented);
        } else {
            [self resolvePickDocumentWithMultipleSelection:call.arguments];
        }
    }
    
}

#pragma mark - Resolvers

- (void)resolvePickDocumentWithMultipleSelection:(BOOL)allowsMultipleSelection {
    
    self.pickerController = [[UIDocumentPickerViewController alloc]
                             initWithDocumentTypes:@[self.fileType]
                             inMode:UIDocumentPickerModeImport];
    
    if (@available(iOS 11.0, *)) {
        self.pickerController.allowsMultipleSelection = allowsMultipleSelection;
    } else if(allowsMultipleSelection) {
       Log(@"Multiple file selection is only supported on iOS 11 and above. Single selection will be used.");
    }
    
    self.pickerController.delegate = self;
    self.pickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.galleryPickerController.allowsEditing = NO;
    [_viewController presentViewController:self.pickerController animated:YES completion:nil];
}

- (void) resolvePickImage {
    
    self.galleryPickerController = [[UIImagePickerController alloc] init];
    self.galleryPickerController.delegate = self;
    self.galleryPickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.galleryPickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    self.galleryPickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [_viewController presentViewController:self.galleryPickerController animated:YES completion:nil];
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

// DocumentPicker delegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    
    [self.pickerController dismissViewControllerAnimated:YES completion:nil];
    NSArray * result = [FileUtils resolvePath:urls];
    
    if([result count] > 1) {
        _result(result);
    } else {
       _result([result objectAtIndex:0]);
    }
    
}


// ImagePicker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *pickedVideoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
    NSURL *pickedImageUrl;
    
    if (@available(iOS 11.0, *)) {
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
    }
    
    _result([pickedVideoUrl != nil ? pickedVideoUrl : pickedImageUrl path]);
}


// AudioPicker delegate
- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    [mediaPicker dismissViewControllerAnimated:YES completion:NULL];
    NSURL *url = [[[mediaItemCollection items] objectAtIndex:0] valueForKey:MPMediaItemPropertyAssetURL];
    if(url == nil) {
        Log(@"Couldn't retrieve the audio file path, either is not locally downloaded or the file DRM protected.");
    }
     _result([url absoluteString]);
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
