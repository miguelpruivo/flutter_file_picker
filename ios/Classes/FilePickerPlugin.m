#import "FilePickerPlugin.h"

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
    if(self){
        self.viewController = viewController;
        
    }
    return self;
}

- (NSString*) resolveType:(NSString*)type {
    
    if ([type isEqualToString:@"PDF"]) {
        return @"com.adobe.pdf";
    }
    else if ([type isEqualToString:@"ANY"])  {
        return @"public.item";
    } else {
        return nil;
    }
    
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
    
    self.fileType = [self resolveType:call.method];
    
    if(self.fileType == nil){
        result(FlutterMethodNotImplemented);
    } else {
        
        [self initPicker];
        _result = result;
        [_viewController presentViewController:self.pickerController animated:YES completion:^{
            if (@available(iOS 11.0, *)) {
                self.pickerController.allowsMultipleSelection = NO;
            }
        }];
        
    }
    
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{
    
    [self.pickerController dismissViewControllerAnimated:YES completion:nil];
    
    NSString * uri;
    
    for (NSURL *url in urls) {
        uri = (NSString *)[url path];
    }
    
    _result(uri);
}

// DocumentInteractionController delegate

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    _result(@"Finished");
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    NSLog(@"Finished");
    return  _viewController;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application {
    
    NSLog(@"Starting to send this puppy to %@", application);
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    
    NSLog(@"We're done sending the document.");
}

@end
