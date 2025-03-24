//
//  NYLDModelManager.m
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import "NYLDModelManager.h"

@interface NYLDModelManager()

@property (nonatomic, strong, readwrite) NSBundle *modelBundle;
@property (nonatomic, strong, readwrite) NSString *resourcePath;
@property (nonatomic, assign, readwrite) NSInteger sceneIndex;
@property (nonatomic, assign, readwrite) NSDictionary *currentModel;
@property (nonatomic, strong) NSMutableArray <NSString *> *modelDirectories;

@end

@implementation NYLDModelManager

+ (instancetype)shared {
    static NYLDModelManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NYLDModelManager alloc] init];
        // Additional initialization code here, if needed
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Frameworks/Live2DSDK" withExtension:@"framework"];
        NSString *bundlePath = [[NSBundle bundleWithURL:url] pathForResource:@"Live2DModels" ofType:@"bundle"];
        NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
        _modelBundle = bundle;
        NSString *resPath = @"Res";
        _resourcePath = [bundlePath stringByAppendingPathComponent:resPath];
        NYLog(@"resourcePath: %@", self.resourcePath);
        
        _modelDirectories = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)setup {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:self.resourcePath error:&error];
    for (NSString *content in contents) {
        NSString *path = [self.resourcePath stringByAppendingPathComponent:content];
        NYLog(@"path:%@", path);
        NSString *modelName = [path lastPathComponent];
        NYLog(@"modelName:%@", modelName);
        
        BOOL isDirectory;
        BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
        if (isDirectory && exists) {
            NSString *targetFile = [path stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.model3.json", modelName]];
            NYLog(@"targetFile: %@", targetFile);
            if ([fileManager fileExistsAtPath:targetFile]) {
                [self.modelDirectories addObject:path];
            }
        }
    }
    
    NYLog(@"modelDirectories: %@", self.modelDirectories);
}

- (void)changeScene:(NSInteger)sceneIndex {
    if (sceneIndex >= self.modelDirectories.count || sceneIndex < 0) {
        return;
    }
    _sceneIndex = sceneIndex;
    NSString *path = [self.modelDirectories objectAtIndex:_sceneIndex];
    NSString *modelName = [path lastPathComponent];
    NSString *targetFile = [path stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.model3.json", modelName]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:targetFile]) {
        NYLog(@"文件不存在: %@", targetFile);
        return ;
    }
    
    NSData *data = [NSData dataWithContentsOfFile:targetFile];
    if (!data) {
        NYLog(@"读取文件失败: %@", targetFile);
        return;
    }
    
    // 解析 JSON
    NSError *error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                   options:kNilOptions
                                                     error:&error];
    if (error) {
        NYLog(@"JSON 解析错误: %@", error);
        return ;
    }
    
    NYLog(@"jsonObject: %@", jsonObject);
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        self.currentModel = jsonObject;
    }
}

+ (void)setup {
    [[NYLDModelManager shared] setup];
    [[NYLDModelManager shared] changeScene:0];
}

@end
