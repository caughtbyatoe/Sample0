//  Copyright (c) 2021 caughtbyatoe
//
//  Sample.h
//  Sample0
//

#pragma once

#include "Scene.h"

#include <metal/metal.h>
#include <vector>

struct Sample
{
    const char *sampleName = nullptr;
    std::vector<const Scene*> scenes = {};
    const char *vertexFunctionName = nullptr;
    const char *fragmenFunctionName = nullptr;
    const float *clearColor = nullptr;
    void(*encoderFunction)(id <MTLRenderCommandEncoder> renderEncoder) = nullptr;
    void(*guiFunction)() = nullptr;
};

const Sample *getNextSample();
