#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
#import <PhotosUI/PHPicker.h>
#endif

@interface FilePickerPlugin : NSObject<FlutterPlugin, FlutterStreamHandler, UIDocumentPickerDelegate, UITabBarDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_14_0
, PHPickerViewControllerDelegate
#endif
>
@end
