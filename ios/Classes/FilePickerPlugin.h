#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface FilePickerPlugin : NSObject<FlutterPlugin, FlutterStreamHandler, UITabBarDelegate, UINavigationControllerDelegate, UIAdaptivePresentationControllerDelegate
#ifdef PICKER_DOCUMENT
    , UIDocumentPickerDelegate
#endif // PICKER_DOCUMENT
>
@end
