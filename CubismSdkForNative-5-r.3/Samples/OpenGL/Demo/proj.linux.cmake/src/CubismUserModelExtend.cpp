/**
 * Copyright(c) Live2D Inc. All rights reserved.
 *
 * Use of this source code is governed by the Live2D Open Software license
 * that can be found at https://www.live2d.com/eula/live2d-open-software-license-agreement_en.html.
 */

#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <Utils/CubismString.hpp>
#include <Motion/CubismMotion.hpp>
#include <Physics/CubismPhysics.hpp>
#include <CubismDefaultParameterId.hpp>
#include <Rendering/OpenGL/CubismRenderer_OpenGLES2.hpp>
#include <Motion/CubismMotionQueueEntry.hpp>
#include <Id/CubismIdManager.hpp>

#include "LAppPal.hpp"
#include "LAppDefine.hpp"
#include "MouseActionManager.hpp"

#include "CubismUserModelExtend.hpp"

using namespace Live2D::Cubism::Framework;
using namespace DefaultParameterId;
using namespace LAppDefine;

namespace {
    /**
    * @bref バッファの作成
    *
    * ファイルをバイトデータとして読み込む
    */
    csmByte* CreateBuffer(const csmChar* path, csmSizeInt* size)
    {
        return LAppPal::LoadFileAsBytes(path, size);
    }

    /**
    * @bref バッファの消去
    *
    * バイトデータの解放
    */
    void DeleteBuffer(csmByte* buffer, const csmChar* path = "")
    {
        LAppPal::ReleaseBytes(buffer);
    }
}

CubismUserModelExtend::CubismUserModelExtend(const std::string modelDirectoryName, const std::string _currentModelDirectory)
    : CubismUserModel()
    , _modelJson(NULL)
    , _userTimeSeconds(0.0f)
    , _modelDirName(modelDirectoryName)
    , _currentModelDirectory(_currentModelDirectory)
    , _textureManager(new LAppTextureManager())
{
    // パラメータIDの取得
    _idParamAngleX = CubismFramework::GetIdManager()->GetId(ParamAngleX);
    _idParamAngleY = CubismFramework::GetIdManager()->GetId(ParamAngleY);
    _idParamAngleZ = CubismFramework::GetIdManager()->GetId(ParamAngleZ);
    _idParamBodyAngleX = CubismFramework::GetIdManager()->GetId(ParamBodyAngleX);
    _idParamEyeBallX = CubismFramework::GetIdManager()->GetId(ParamEyeBallX);
    _idParamEyeBallY = CubismFramework::GetIdManager()->GetId(ParamEyeBallY);
}

CubismUserModelExtend::~CubismUserModelExtend()
{
    // モデルの設定データの解放
    ReleaseModelSetting();

    // テクスチャマネージャーの解放
    delete _textureManager;
}

void CubismUserModelExtend::LoadAssets(const Csm::csmChar* fileName)
{
    csmSizeInt size;
    const csmString path = csmString(_currentModelDirectory.c_str()) + fileName;

    csmByte* buffer = CreateBuffer(path.GetRawString(), &size);
    _modelJson = new CubismModelSettingJson(buffer, size);
    DeleteBuffer(buffer, path.GetRawString());

    // モデルの生成
    SetupModel();
}

void CubismUserModelExtend::SetupModel()
{
    _updating = true;
    _initialized = false;

    csmByte* buffer;
    csmSizeInt size;

    //Cubism Model
    if (strcmp(_modelJson->GetModelFileName(), ""))
    {
        csmString path = _modelJson->GetModelFileName();
        path = csmString(_currentModelDirectory.c_str()) + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadModel(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // 表情データの読み込み
    if (_modelJson->GetExpressionCount() > 0)
    {
        const csmInt32 count = _modelJson->GetExpressionCount();
        for (csmInt32 i = 0; i < count; i++)
        {
            csmString name = _modelJson->GetExpressionName(i);
            csmString path = _modelJson->GetExpressionFileName(i);
            path = csmString(_currentModelDirectory.c_str()) + path;

            buffer = CreateBuffer(path.GetRawString(), &size);
            ACubismMotion* motion = LoadExpression(buffer, size, name.GetRawString());

            if (motion)
            {
                if (_expressions[name])
                {
                    ACubismMotion::Delete(_expressions[name]);
                    _expressions[name] = nullptr;
                }
                _expressions[name] = motion;
            }

            DeleteBuffer(buffer, path.GetRawString());
        }
    }

    //ポーズデータの読み込み
    if (strcmp(_modelJson->GetPoseFileName(), ""))
    {
        csmString path = _modelJson->GetPoseFileName();
        path = csmString(_currentModelDirectory.c_str()) + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadPose(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // 物理演算データの読み込み
    if (strcmp(_modelJson->GetPhysicsFileName(), ""))
    {
        csmString path = _modelJson->GetPhysicsFileName();
        path = csmString(_currentModelDirectory.c_str()) + path;

        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadPhysics(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // モデルに付属するユーザーデータの読み込み
    if (strcmp(_modelJson->GetUserDataFile(), ""))
    {
        csmString path = _modelJson->GetUserDataFile();
        path = csmString(_currentModelDirectory.c_str()) + path;
        buffer = CreateBuffer(path.GetRawString(), &size);
        LoadUserData(buffer, size);
        DeleteBuffer(buffer, path.GetRawString());
    }

    // Layout
    csmMap<csmString, csmFloat32> layout;
    _modelJson->GetLayoutMap(layout);
    // レイアウト情報から位置を設定
    _modelMatrix->SetupFromLayout(layout);

    // パラメータを保存
    _model->SaveParameters();

    // モーションデータの読み込み
    for (csmInt32 i = 0; i < _modelJson->GetMotionGroupCount(); i++)
    {
        const csmChar* group = _modelJson->GetMotionGroupName(i);
        // モーションデータをグループ名から一括でロードする
        PreloadMotionGroup(group);
    }

    _motionManager->StopAllMotions();

    // レンダラの作成
    CreateRenderer();

    // テクスチャのセットアップ
    SetupTextures();

    _updating = false;
    _initialized = true;
}

void CubismUserModelExtend::PreloadMotionGroup(const csmChar* group)
{
    // グループに登録されているモーション数を取得
    const csmInt32 count = _modelJson->GetMotionCount(group);

    for (csmInt32 i = 0; i < count; i++)
    {
        //ex) idle_0
        // モーションのファイル名とパスの取得
        csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, i);
        csmString path = _modelJson->GetMotionFileName(group, i);
        path = csmString(_currentModelDirectory.c_str()) + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = CreateBuffer(path.GetRawString(), &size);
        // モーションデータの読み込み
        CubismMotion* tmpMotion = static_cast<CubismMotion*>(LoadMotion(buffer, size, name.GetRawString(), NULL, NULL, _modelJson, group, i));

        if (tmpMotion)
        {
            if (_motions[name])
            {
                // インスタンスを破棄
                ACubismMotion::Delete(_motions[name]);
            }
            _motions[name] = tmpMotion;
        }

        DeleteBuffer(buffer, path.GetRawString());
    }
}

void CubismUserModelExtend::ReleaseModelSetting()
{
    // モーションの解放
    for (Csm::csmMap<Csm::csmString, Csm::ACubismMotion*>::const_iterator iter = _motions.Begin(); iter != _motions.End(); ++iter)
    {
        Csm::ACubismMotion::Delete(iter->Second);
    }

    _motions.Clear();

    // すべての表情データを解放する
    for (Csm::csmMap<Csm::csmString, Csm::ACubismMotion*>::const_iterator iter = _expressions.Begin(); iter != _expressions.End(); ++iter)
    {
        Csm::ACubismMotion::Delete(iter->Second);
    }

    _expressions.Clear();

    delete(_modelJson);
}

/**
* @brief   引数で指定したモーションの再生を開始する。
*
* @param[in]   group                       モーショングループ名
* @param[in]   no                          グループ内の番号
* @param[in]   priority                    優先度
* @return                                  開始したモーションの識別番号を返す。個別のモーションが終了したか否かを判定するIsFinished()の引数で使用する。開始できない時は「-1」
*/
Csm::CubismMotionQueueEntryHandle CubismUserModelExtend::StartMotion(const Csm::csmChar* group, Csm::csmInt32 no, Csm::csmInt32 priority)
{
    // モーション数が取得出来なかった、もしくは0の時
    if (!(_modelJson->GetMotionCount(group)))
    {
        return Csm::InvalidMotionQueueEntryHandleValue;
    }

    if (priority == LAppDefine::PriorityForce)
    {
        // 予約中のモーションの優先度を設定する
        _motionManager->SetReservePriority(priority);
    }
    else if (!_motionManager->ReserveMotion(priority))
    {
        return Csm::InvalidMotionQueueEntryHandleValue;
    }

    // 指定された.motion3.jsonのファイル名を取得
    const Csm::csmString fileName = _modelJson->GetMotionFileName(group, no);

    //ex) idle_0
    // モーションのデータを生成
    csmString name = Utils::CubismString::GetFormatedString("%s_%d", group, no);
    CubismMotion* motion = static_cast<CubismMotion*>(_motions[name.GetRawString()]);
    csmBool autoDelete = false;

    if (!motion)
    {
        csmString path = fileName;
        path = csmString(_currentModelDirectory.c_str()) + path;

        csmByte* buffer;
        csmSizeInt size;
        buffer = CreateBuffer(path.GetRawString(), &size);
        // 一番先頭のモーションを読み込む
        motion = static_cast<CubismMotion*>(LoadMotion(buffer, size, NULL, NULL, NULL, _modelJson, group, no));

        if (motion)
        {
            // 終了時にメモリから削除
            autoDelete = true;
        }

        DeleteBuffer(buffer, path.GetRawString());
    }

    // 優先度を設定してモーションを始める
    return  _motionManager->StartMotionPriority(motion, autoDelete, priority);
}

void CubismUserModelExtend::ModelParamUpdate()
{
    // 前のフレームとの差分を取得
    const Csm::csmFloat32 deltaTimeSeconds = LAppPal::GetDeltaTime();
    _userTimeSeconds += deltaTimeSeconds;

    // ドラッグ情報を更新
    _dragManager->Update(deltaTimeSeconds);
    _dragX = _dragManager->GetX();
    _dragY = _dragManager->GetY();

    // モーションによるパラメータ更新の有無
    Csm::csmBool motionUpdated = false;

    //-----------------------------------------------------------------
    // 前回セーブされた状態をロード
    _model->LoadParameters();

    if (_motionManager->IsFinished())
    {
        // モーションの再生がない場合、始めに登録されているモーションを再生する
        StartMotion(LAppDefine::MotionGroupIdle, 0, LAppDefine::PriorityIdle);
    }
    else
    {
        // モーションを更新し、パラメータを反映
        motionUpdated = _motionManager->UpdateMotion(_model, deltaTimeSeconds);
    }

    // 状態を保存
    _model->SaveParameters();
    //-----------------------------------------------------------------

    if (_expressionManager)
    {
        // 表情でパラメータ更新（相対変化）
        _expressionManager->UpdateMotion(_model, deltaTimeSeconds);
    }

    //ドラッグによる変化
    /**
    *ドラッグによる顔の向きの調整
    * -30から30の値を加える
    */
    _model->AddParameterValue(_idParamAngleX, _dragX * 30.0f);
    _model->AddParameterValue(_idParamAngleY, _dragY * 30.0f);
    _model->AddParameterValue(_idParamAngleZ, _dragX * _dragY * -30.0f);

    //ドラッグによる体の向きの調整
    _model->AddParameterValue(_idParamBodyAngleX, _dragX * 10.0f); // -10から10の値を加える

    //ドラッグによる目の向きの調整
    _model->AddParameterValue(_idParamEyeBallX, _dragX); // -1から1の値を加える
    _model->AddParameterValue(_idParamEyeBallY, _dragY);

    // 物理演算の設定
    if (_physics)
    {
        _physics->Evaluate(_model, deltaTimeSeconds);
    }

    // ポーズの設定
    if (_pose)
    {
        _pose->UpdateParameters(_model, deltaTimeSeconds);
    }

    // モデルのパラメータ情報を更新
    _model->Update();
}

void CubismUserModelExtend::Draw(Csm::CubismMatrix44& matrix)
{
    if (!_model)
    {
        return;
    }

    // 現在の行列に行列を乗算
    matrix.MultiplyByMatrix(_modelMatrix);

    // 行列をモデルビュープロジェクション行列を設定
    GetRenderer<Csm::Rendering::CubismRenderer_OpenGLES2>()->SetMvpMatrix(&matrix);

    // モデルの描画を命令・実行する
    GetRenderer<Csm::Rendering::CubismRenderer_OpenGLES2>()->DrawModel();
}

void CubismUserModelExtend::SetupTextures()
{
    for (csmInt32 modelTextureNumber = 0; modelTextureNumber < _modelJson->GetTextureCount(); modelTextureNumber++)
    {
        // テクスチャ名が空文字だった場合はロード・バインド処理をスキップ
        if (!strcmp(_modelJson->GetTextureFileName(modelTextureNumber), ""))
        {
            continue;
        }

        // OpenGLのテクスチャユニットにテクスチャをロードする
        csmString texturePath = _modelJson->GetTextureFileName(modelTextureNumber);
        texturePath = csmString(_currentModelDirectory.c_str()) + texturePath;

        LAppTextureManager::TextureInfo* texture = _textureManager->CreateTextureFromPngFile(texturePath.GetRawString());
        const csmInt32 glTextueNumber = texture->id;

        // OpenGL
        GetRenderer<Rendering::CubismRenderer_OpenGLES2>()->BindTexture(modelTextureNumber, glTextueNumber);
    }

    // 乗算済みアルファ値の有効化・無効化を設定
    GetRenderer<Rendering::CubismRenderer_OpenGLES2>()->IsPremultipliedAlpha(false);
}

void CubismUserModelExtend::ModelOnUpdate(GLFWwindow* window)
{
    int width, height;
    // ウィンドウサイズを取得
    glfwGetWindowSize(window, &width, &height);

    Csm::CubismMatrix44 projection;
    // 念のため単位行列に初期化
    projection.LoadIdentity();

    if (_model->GetCanvasWidth() > 1.0f && width < height)
    {
        // 横に長いモデルを縦長ウィンドウに表示する際モデルの横サイズでscaleを算出する
        GetModelMatrix()->SetWidth(2.0f);
        projection.Scale(1.0f, static_cast<float>(width) / static_cast<float>(height));
    }
    else
    {
        projection.Scale(static_cast<float>(height) / static_cast<float>(width), 1.0f);
    }

    // 必要があればここで乗算
    if (MouseActionManager::GetInstance()->GetViewMatrix() != NULL)
    {
        projection.MultiplyByMatrix(MouseActionManager::GetInstance()->GetViewMatrix());
    }

    // モデルのパラメータを更新
    ModelParamUpdate();

    // モデルの描画を更新
    Draw(projection); ///< 参照渡しなのでprojectionは変質する
}
