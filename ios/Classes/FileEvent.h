@interface FileEvent : NSObject

@property(nonatomic, strong) NSString *type;
@property(nonatomic, strong) NSObject *value;

- (instancetype)init:(NSString *)type andValue:(NSObject *)value;

- (NSDictionary *)toData;

@end
