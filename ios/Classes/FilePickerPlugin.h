#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Photos/Photos.h>
#import <PhotosUI/PHPicker.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface FilePickerPlugin : NSObject<FlutterPlugin, FlutterStreamHandler, UIDocumentPickerDelegate, UITabBarDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, PHPickerViewControllerDelegate>
@end
