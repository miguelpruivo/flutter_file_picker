#import "FilePickerPlugin.h"

@implementation FilePickerPlugin
 FlutterResult _result;
    UIViewController *_viewController;
    UIDocumentPickerViewController *_pickerController;
    UIDocumentInteractionController *_interactionController;

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
    if (self) {
        _viewController = viewController;
        _pickerController = [[UIDocumentPickerViewController alloc]
                                                               initWithDocumentTypes:@[@"com.adobe.pdf"]
                                                               inMode:UIDocumentPickerModeImport];
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


  if ([@"pickPDF" isEqualToString:call.method]) {

      _pickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
      _pickerController.delegate = self;

      _result = result;
      [_viewController presentViewController:_pickerController animated:YES completion:^{
          if (@available(iOS 11.0, *)) {
              _pickerController.allowsMultipleSelection = NO;
          }
      }];

  }
  else {
      result(FlutterMethodNotImplemented);
  }
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls{

    [_pickerController dismissViewControllerAnimated:YES completion:nil];

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
