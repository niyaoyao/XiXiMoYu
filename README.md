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
        - [x] `ViewController` remove C++ interface/type in header files.
        - [x] Change Background
        - [x] Change Model No.
        - [x] Render Stage Controller

    - [ ] App Development
        - [ ] Menu List Bar
            - [x] Change Model
                - [x] Collection View Circle Transmation
            - [x] Change Background
            - [ ] Creative Functions( Pose/Animation/Play Music)
            - [ ] Settings/Me
                - [ ] Privacy
                - [ ] User
                - [x] Dynamic Key: **OpenRouter Key Request JSON AES encrypt**
                - [ ] AI Model Settings
                    - [ ] Model List: **Request JSON AES encrypt**
                    - [ ] Request Message Prompt Settings
                        - [ ] user
                        - [ ] system
                - [x] ICP
                - [x] Version
                - [ ] Locale Language
    - [x] AI Speech
        - [x] **SSE Text Stream** 
        - [x] Mouth Control
        - [x] Text to Speech
        - [ ] Speech to Text

    - [ ] `NYLDModel` instead of `LAppModel`
        - [x] Change Model Mouth Angle
        - [ ] a i e o u

4. [x] App Icon
5. [x] Renew Account Plan 
6. [ ] Small Business Plan
7. [ ] ICP
    - [x] Host 2025-03-27 ~ 2025-04-09
    - [x] App 2025-04-09 ~ 2025-04-28/ (EvaAI 2025-05-06)
    - [ ] Host Police (Optional)
    - [ ] App Police (Optional)
8. [ ] Submit Review

### Phase 2
- 3D Model Control
- 3D Model Render (Unity3D/**Metal** )
- User System & VIP
- Advertise