#import "FileEvent.h"

@implementation FileEvent

- (instancetype) init: (NSString *)type andValue: (NSObject*)value {

    self = [super init];

    if (self) {
        self.type = type;
        self.value = value;
    }
    return self;
}

- (NSDictionary *)toData {
    NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
    [data setValue:self.type forKey:@"type"];
    [data setValue:self.value forKey:@"value"];
    return data;
}

@end
