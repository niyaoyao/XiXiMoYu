# XiXiMoYu
## Target
### Live2DRender
- Live2DSDK is a C++ Framework is not compatible with Swift
- Live2DSDK ignore platform features like ARC
- Lots of Shit code for converting C++ to Objective-C,  then Objective-C to C++
### Create an App with Live2DSDK

## Plans
| 阶段     | 任务     |时间|
|----------|----------|----------|
| 第一阶段  | 1. 做出 live2d.pavostudio.com/doc/en-us/ios/ 基本功能；2. App 备案；3. 上架提审第1版 | 2025.03~2025.04 |
| 第二阶段  | 2. 接入 AI | 2025.04~2025.05 |
| 第三阶段  | 3. 接入会员广告 | 2025.05~2025.06 |

### Phase 1
1. [x] Create iOS Project 
2. [x] iOS Integration Script
    - [x] Integrate Assets Automatic
    - [x] Integrate Library Automatic 
    - [x] Integrate Demo Code Automatic
3. [ ] Further Development
    - [x] Basic Foundation: Convert the C++ Class to Objective-C Class
        - [x] `NYLDModelManager` instead of `LAppLive2DManager`
        - [x] `NYLDSDKManager` instead of `AppDelegate`
        - [x] `NYLDStagingGLViewController` to render GL Model.
        ~~- Wrap `LAppModel` 🌟~~
        - [x] `ViewController` remove C++ interface/type in header files.
        ~~- `LAppLive2DManager`  remove C++ interface/type in header files.~~
        ~~- `LAppLive2DManager` optimize the flow for manage model, bridge C++ functions.~~
        ~~- Wrap `LAppPal` `LAppSprite`~~
        ~~- Wrap `LAppSprite`~~
    - [ ] Change Pose
    - [ ] Play Animation
    - [ ] Change Background
4. [x] Renew Account Plan & 
5. [ ] Small Business Plan
6. [ ] ICP
    - [ ]  Host
    - [ ]  App
7. [ ] Submit Review

### Phase 2