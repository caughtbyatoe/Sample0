//  Copyright (c) 2021 caughtbyatoe
//
//  SampleNoise.mm
//  Sample0
//

#include "SampleNoise.h"

#include "Shaders.h"

#include "ImGui/imgui.h"

const Scene unitQuadScene {
    /* name = */ "unit quad",
    /* cam = */ {
        /* r = */ 1.0,
        /* phi = */ 90.0,
        /* theta = */ 90.0,
        /* fov = */ 65.0,
        /* near = */ 0.01,
        /* far = */ 100.0,
    },
    /* vars = */ {
        /* rMin = */ 0.1,
        /* rMax = */ 10.0,
        /* worldTrans = */ { 0.0, 0.0, 0.0 },
        /* worldRot = */ { 0.0, 0.0, 0.0 },
        /* worldScale = */ { 1.0, 1.0, 1.0 },
    },
    /* meshes = */ {
        /* [0] = */ {
            /* name = */ "quad0",
            /* vertTbl = */ {
                { -0.5, -0.5, 0.0 },
                {  0.5, -0.5, 0.0 },
                {  0.5,  0.5, 0.0 },
                { -0.5,  0.5, 0.0 },
            },
            /* vertClr = */ {
                { 1.0, 1.0, 1.0 },
                { 1.0, 1.0, 1.0 },
                { 1.0, 1.0, 1.0 },
                { 1.0, 1.0, 1.0 },
            },
            /* vertUvw = */ {
                { 0.0, 0.0, 0.0 },
                { 1.0, 0.0, 0.0 },
                { 1.0, 1.0, 0.0 },
                { 0.0, 1.0, 0.0 },
            },
            /* faces = */ {
                { 0, 1, 2, 3 },
            },
        },
    }
};

static float clearColor[] = { 0.0f, 0.0f, 0.0f, 1.0f };

// new perlin noise permutation table
static int permutation[] = { 151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
   };

static ShaderUniforms shaderUniforms;
static int newPerlinP[512];

static void encoder(id <MTLRenderCommandEncoder> renderEncoder)
{
    static bool firstTime = true;
    if (firstTime) {
        shaderUniforms.uvwScale = simd_make_float3(1.0, 1.0, 1.0);
        shaderUniforms.octaves = 1;
        shaderUniforms.zOffset = 0.0;
        shaderUniforms.patternType = PatternTypeUvw;
        shaderUniforms.noiseType = NoiseTypePerlin;
        shaderUniforms.useTurbulence = 0;
        for (int i = 0; i < 256; ++i) {
            newPerlinP[i + 256] = newPerlinP[i] = permutation[i];
        }
        firstTime = false;
    }
    [renderEncoder setFragmentBytes:&shaderUniforms length:sizeof(ShaderUniforms) atIndex:1];
    [renderEncoder setFragmentBytes:newPerlinP length:sizeof(newPerlinP) atIndex:2];
}

static void guiDraw()
{
    // Pattern gui
    if (ImGui::RadioButton("Uvw", shaderUniforms.patternType == PatternTypeUvw)) { shaderUniforms.patternType = PatternTypeUvw; }
    ImGui::SameLine();
    if (ImGui::RadioButton("Random", shaderUniforms.patternType == PatternTypeRandom)) { shaderUniforms.patternType = PatternTypeRandom; }
    ImGui::SameLine();
    if (ImGui::RadioButton("Noise", shaderUniforms.patternType == PatternTypeNoise)) { shaderUniforms.patternType = PatternTypeNoise; }
    ImGui::SameLine();
    if (ImGui::RadioButton("Fbm", shaderUniforms.patternType == PatternTypeFbm)) { shaderUniforms.patternType = PatternTypeFbm; }

    if (ImGui::RadioButton("Perlin", shaderUniforms.noiseType == NoiseTypePerlin)) { shaderUniforms.noiseType = NoiseTypePerlin; }
    ImGui::SameLine();
    if (ImGui::RadioButton("New Perlin", shaderUniforms.noiseType == NoiseTypeNewPerlin)) { shaderUniforms.noiseType = NoiseTypeNewPerlin; }
    ImGui::SameLine();
    if (ImGui::RadioButton("Gradient", shaderUniforms.noiseType == NoiseTypeGradient)) { shaderUniforms.noiseType = NoiseTypeGradient; }
    
    ImGui::Checkbox("Use Turbulence", (bool *)&shaderUniforms.useTurbulence);

    ImGui::InputInt("Octave(s)", (int*) &shaderUniforms.octaves);
    ImGui::SliderFloat("z offset", (float*) &shaderUniforms.zOffset, 0.0, 1.0);
    ImGui::InputFloat3("UvwScale", (float*) &shaderUniforms.uvwScale);
}

static const Sample sampleNoise {
    /* sampleName = */ "noise",
    /* scenes = */ {
        /* [0] = */ &unitQuadScene
    },
    /* vertexFunctionName = */ "vertexShader",
    /* fragmentFunctionName = */ "sampleNoiseFragmentShader",
    /* clearColor = */ clearColor,
    /* encoderFunction = */ encoder,
    /* guiFunction = */ guiDraw,
};

const Sample* getSampleNoise()
{
    return &sampleNoise;
}
