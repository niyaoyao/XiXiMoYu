/**
 * Copyright(c) Live2D Inc. All rights reserved.
 *
 * Use of this source code is governed by the Live2D Open Software license
 * that can be found at https://www.live2d.com/eula/live2d-open-software-license-agreement_en.html.
 */

#import <Foundation/Foundation.h>
#import "LAppTextureManager.h"
#import <GLKit/GLKit.h>
#import <iostream>
#define STBI_NO_STDIO
#define STBI_ONLY_PNG
#define STB_IMAGE_IMPLEMENTATION
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#pragma clang diagnostic ignored "-Wunused-function"
#import "stb_image.h"
#pragma clang diagnostic pop
#import "LAppPal.h"


@interface LAppTextureManager()

@property (nonatomic) Csm::csmVector<TextureInfo*> textures;

@end

@implementation LAppTextureManager

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [self releaseTextures];
}


- (TextureInfo*) createTextureFromPngFile:(std::string)fileName
{

    //search loaded texture already.
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++)
    {
        if (_textures[i]->fileName == fileName)
        {
            return _textures[i];
        }
    }

    GLuint textureId;
    int width, height, channels;
    unsigned int size;
    unsigned char* png;
    unsigned char* address;

    address = LAppPal::LoadFileAsBytes(fileName, &size);

    // png情報を取得する
    png = stbi_load_from_memory(
                                address,
                                static_cast<int>(size),
                                &width,
                                &height,
                                &channels,
                                STBI_rgb_alpha);

    {
#ifdef PREMULTIPLIED_ALPHA_ENABLE
        unsigned int* fourBytes = reinterpret_cast<unsigned int*>(png);
        for (int i = 0; i < width * height; i++)
        {
            unsigned char* p = png + i * 4;
            int tes = [self pemultiply:p[0] Green:p[1] Blue:p[2] Alpha:p[3]];
            fourBytes[i] = tes;
        }
#endif
    }

    // OpenGL用のテクスチャを生成する
    glGenTextures(1, &textureId);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, png);
    glGenerateMipmap(GL_TEXTURE_2D);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindTexture(GL_TEXTURE_2D, 0);


    // 解放処理
    stbi_image_free(png);
    LAppPal::ReleaseBytes(address);

    TextureInfo* textureInfo = new TextureInfo;
    textureInfo->fileName = fileName;
    textureInfo->width = width;
    textureInfo->height = height;
    textureInfo->textureId = textureId;
    _textures.PushBack(textureInfo);

    return textureInfo;
}

- (unsigned int)pemultiply:(unsigned char)red Green:(unsigned char)green Blue:(unsigned char)blue Alpha:(unsigned char) alpha
{
    return static_cast<unsigned>(\
                                 (red * (alpha + 1) >> 8) | \
                                 ((green * (alpha + 1) >> 8) << 8) | \
                                 ((blue * (alpha + 1) >> 8) << 16) | \
                                 (((alpha)) << 24)   \
                                 );
}
- (void)releaseTextures
{
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++)
    {
        glDeleteTextures(1, &(_textures[i]->textureId));
        delete _textures[i];
    }

    _textures.Clear();
}

- (void)releaseTextureWithId:(Csm::csmUint32)textureId
{
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++)
    {
        if (_textures[i]->textureId != textureId)
        {
            continue;
        }
        glDeleteTextures(1, &(_textures[i]->textureId));
        delete _textures[i];
        _textures.Remove(i);
        break;
    }
}

- (void)releaseTextureByName:(std::string)fileName;
{
    for (Csm::csmUint32 i = 0; i < _textures.GetSize(); i++)
    {
        if (_textures[i]->fileName == fileName)
        {
            glDeleteTextures(1, &(_textures[i]->textureId));
            delete _textures[i];
            _textures.Remove(i);
            break;
        }
    }
}

@end
