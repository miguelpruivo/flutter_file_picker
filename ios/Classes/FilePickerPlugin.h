#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface FilePickerPlugin : NSObject<FlutterPlugin, UIDocumentPickerDelegate, UITabBarDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@end
