#import "FilePickerPlugin.h"
#import "FileUtils.h"

@interface FilePickerPlugin()
@property (nonatomic) FlutterResult result;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIDocumentPickerViewController *pickerController;
@property (nonatomic) UIDocumentInteractionController *interactionController;
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

- (void)initPicker {
    
    self.pickerController = [[UIDocumentPickerViewController alloc]
                             initWithDocumentTypes:@[self.fileType]
                             inMode:UIDocumentPickerModeImport];
    
    self.pickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.pickerController.delegate = self;
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
    else {
        self.fileType = [FileUtils resolveType:call.method];
        
        if(self.fileType == nil){
            result(FlutterMethodNotImplemented);
        } else {
            [self initPicker];
            [_viewController presentViewController:self.pickerController animated:YES completion:^{
                if (@available(iOS 11.0, *)) {
                    self.pickerController.allowsMultipleSelection = NO;
                }
            }];
            
        }
    }
    
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    
    [self.pickerController dismissViewControllerAnimated:YES completion:nil];
    _result([FileUtils resolvePath:urls]);
}


// VideoPicker delegate
- (void) resolvePickVideo{
    
    UIImagePickerController *videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    videoPicker.mediaTypes = @[(NSString*)kUTTypeMovie, (NSString*)kUTTypeAVIMovie, (NSString*)kUTTypeVideo, (NSString*)kUTTypeMPEG4];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    [self.viewController presentViewController:videoPicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    _result([videoURL path]);
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    _result = nil;
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    _result = nil;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
