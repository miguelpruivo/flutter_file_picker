#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface FilePickerPlugin : NSObject<FlutterPlugin, UIDocumentPickerDelegate, UITabBarDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@end
