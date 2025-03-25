//
//  NYLDModelManager.m
//  Live2DSDK
//
//  Created by niyao on 3/18/25.
//

#import "NYLDModelManager.h"
#import <CubismFramework.hpp>
#import <Foundation/Foundation.h>
#import <CubismMatrix44.hpp>
#import <csmVector.hpp>
#import <csmString.hpp>
#import "LAppModel.h"

#import <string.h>
#import <stdlib.h>
#import <GLKit/GLKit.h>
#import "AppDelegate.h"
#import "ViewController.h"
#import "LAppModel.h"
#import "LAppDefine.h"
#import "LAppPal.h"
@interface NYLDModelManager()

@property (nonatomic) Csm::CubismMatrix44 *viewMatrix; //モデル描画に用いるView行列
@property (nonatomic) Csm::csmVector<LAppModel*> models; //モデルインスタンスのコンテナ
@property (nonatomic) Csm::csmVector<Csm::csmString> modelDir; ///< モデルディレクトリ名のコンテナ

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
        _sceneIndex = 0;
        _viewMatrix = new Csm::CubismMatrix44();
    }
    return self;
}

- (void)setup {
    _modelDir.Clear();
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
                _modelDir.PushBack(Csm::csmString([modelName UTF8String]));
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
    
    NSError *error = nil;
    NSData *jsonData = [NSData dataWithContentsOfFile:targetFile options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
        return ;
    }
    
    // 使用 NSJSONReadingMutableContainers 选项可以直接得到可变容器
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&error];
    
    if (error) {
        NSLog(@"JSON parsing error: %@", error.localizedDescription);
        return ;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        self.currentModel = (NSDictionary *)jsonObject;
    }
    
    if (LAppDefine::DebugLogEnable)
    {
        LAppPal::PrintLogLn("[APP]model index: %d", _sceneIndex);
    }

    // model3.jsonのパスを決定する.
    // ディレクトリ名とmodel3.jsonの名前を一致させておくこと.
    const Csm::csmString& model = [[self.modelDirectories[sceneIndex].lastPathComponent stringByReplacingOccurrencesOfString:@".model3.json" withString:@""] UTF8String]; // _modelDir[sceneIndex];

    Csm::csmString modelPath(LAppDefine::ResourcesPath);
    modelPath += model;
    modelPath.Append(1, '/');

    Csm::csmString modelJsonName(model);
    modelJsonName += ".model3.json";

    [self releaseAllModel];
    _models.PushBack(new LAppModel());
    _models[0]->LoadAssets(modelPath.GetRawString(), modelJsonName.GetRawString());

    /*
     * モデル半透明表示を行うサンプルを提示する。
     * ここでUSE_RENDER_TARGET、USE_MODEL_RENDER_TARGETが定義されている場合
     * 別のレンダリングターゲットにモデルを描画し、描画結果をテクスチャとして別のスプライトに張り付ける。
     */
    {
#if defined(USE_RENDER_TARGET)
        // LAppViewの持つターゲットに描画を行う場合、こちらを選択
        SelectTarget useRenderTarget = SelectTarget_ViewFrameBuffer;
#elif defined(USE_MODEL_RENDER_TARGET)
        // 各LAppModelの持つターゲットに描画を行う場合、こちらを選択
        SelectTarget useRenderTarget = SelectTarget_ModelFrameBuffer;
#else
        // デフォルトのメインフレームバッファへレンダリングする(通常)
        SelectTarget useRenderTarget = SelectTarget_None;
#endif

#if defined(USE_RENDER_TARGET) || defined(USE_MODEL_RENDER_TARGET)
        // モデル個別にαを付けるサンプルとして、もう1体モデルを作成し、少し位置をずらす
        _models.PushBack(new LAppModel());
        _models[1]->LoadAssets(modelPath.GetRawString(), modelJsonName.GetRawString());
        _models[1]->GetModelMatrix()->TranslateX(0.2f);
#endif

        float clearColorR = 0.0f;
        float clearColorG = 0.0f;
        float clearColorB = 0.0f;

//        AppDelegate* delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
//        ViewController* view = [delegate viewController];
//
//        [view SwitchRenderingTarget:useRenderTarget];
//        [view SetRenderTargetClearColor:clearColorR g:clearColorG b:clearColorB];
    }
}

- (void)releaseAllModel
{
    for (Csm::csmUint32 i = 0; i < _models.GetSize(); i++)
    {
        delete _models[i];
    }

    _models.Clear();
}

+ (void)setup {
    [[NYLDModelManager shared] setup];
    [[NYLDModelManager shared] changeScene:0];
}

@end
