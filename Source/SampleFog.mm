//  Copyright (c) 2021 caughtbyatoe
//
//  SampleFog.mm
//  Sample0
//
//

#include "Sample.h"

#include "Shaders.h"

#include "ImGui/imgui.h"

const Scene cornellBoxScene {
    /* name = */ "cornell box",
    /* cam = */ {
        /* r = */ 1500.0,
        /* phi = */ 90.0,
        /* theta = */ 90.0,
        /* fov = */ 65.0,
        /* near = */ 1.0,
        /* far = */ 10000.0,
    },
    /* vars = */ {
        /* rMin = */ 1.0,
        /* rMax   = */ 3000.0,
        /* worldTrans = */ { -260.0, -260.0, 0.0 },
        /* worldRot = */ { 0.0, 0.0, 0.0 },
        /* worldScale = */ { 1.0, 1.0, 1.0 },
    },
    /* meshes = */ {
        /* [0] = */ {
            /* name = */ "ceiling light",
            /* vertTbl = */ {
                { 343, 548.29999, 227 }, // -.5 from ceiling
                { 343, 548.29999, 332 },
                { 213, 548.29999, 332 },
                { 213, 548.29999, 227 }
            },
            /* vertClr = */ {
                { 1.0, 1.0, 1.0 },
                { 1.0, 1.0, 1.0 },
                { 1.0, 1.0, 1.0 },
                { 1.0, 1.0, 1.0 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 }
            }
        },
        /* [1] = */ {
            /* name = */ "floor",
            /* vertTbl = */ {
                { 549.59998, 0, 0 },
                { 0,         0, 0 },
                { 0,         0, 559.20001 },
                { 549.59998, 0, 559.20001 }
            },
            /* vertClr = */ {
                { 0.4, 0.4, 0.4 },
                { 0.4, 0.4, 0.4 },
                { 0.4, 0.4, 0.4 },
                { 0.4, 0.4, 0.4 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 }
            }
        },
        /* [2] = */ {
            /* name = */ "ceiling",
            /* vertTbl = */ {
                { 549.59998, 548.79999, 0 },
                { 549.59998, 548.79999, 559.20001 },
                { 0,         548.79999, 559.20001 },
                { 0,         548.79999, 0 }
            },
            /* vertClr = */ {
                { 0.6, 0.6, 0.6 },
                { 0.6, 0.6, 0.6 },
                { 0.6, 0.6, 0.6 },
                { 0.6, 0.6, 0.6 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 }
            }
        },
        /* [3] = */ {
            /* name = */ "back wall",
            /* vertTbl = */ {
                { 0,         0,         0 },
                { 549.59998, 0,         0 },
                { 549.59998, 548.79999, 0 },
                { 0,         548.79999, 0 }
            },
            /* vertClr = */ {
                { 0.5, 0.5, 0.5 },
                { 0.5, 0.5, 0.5 },
                { 0.5, 0.5, 0.5 },
                { 0.5, 0.5, 0.5 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 }
            }
        },
        /* [4] = */ {
            /* name = */ "green wall",
            /* vertTbl = */ {
                { 0, 0,         559.20001 },
                { 0, 0,         0 },
                { 0, 548.79999, 0 },
                { 0, 548.79999, 559.20001 }
            },
            /* vertClr = */ {
                { 0.0, 0.5, 0.0 },
                { 0.0, 0.5, 0.0 },
                { 0.0, 0.5, 0.0 },
                { 0.0, 0.5, 0.0 },
            },
            /* vertUvw = */ {},
            /* quadTbl = */ {
                { 0, 1, 2, 3 }
            }
        },
        /* [5] = */ {
            /* name = */ "red wall",
            /* vertTbl = */ {
                { 549.59998, 0,         0 },
                { 549.59998, 0,         559.20001 },
                { 549.59998, 548.79999, 559.20001 },
                { 549.59998, 548.79999, 0 }
            },
            /* vertClr = */ {
                { 0.5, 0.0, 0.0 },
                { 0.5, 0.0, 0.0 },
                { 0.5, 0.0, 0.0 },
                { 0.5, 0.0, 0.0 },
            },
            /* vertUvw = */ {},
            /* quadTbl = */ {
                { 0, 1, 2, 3 }
            }
        },
        /* [6] = */ {
            /* name  */ "large box",
            /* vertTbl = */ {
                { 130.000000, 330.000000, 65.000000 },
                { 82.000000, 330.000000, 225.000000 },
                { 240.000000, 330.000000, 272.000000 },
                { 290.000000, 330.000000, 114.000000 },
                { 290.000000, 0.000000, 114.000000 },
                { 240.000000, 0.000000, 272.000000 },
                { 82.000000, 0.000000, 225.000000 },
                { 130.000000, 0.000000, 65.000000 }
            },
            /* vertClr = */ {
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
                { 0.5, 0.5, 0.0 },
            },
            /* vertUvw = */ {},
            /* quadTbl = */ {
                { 0, 1, 2, 3 },
                { 4, 3, 2, 5 },
                { 7, 0, 3, 4 },
                { 6, 1, 0, 7 },
                { 5, 2, 1, 6 },
                { 4, 5, 6, 7 }
            }
        },
        /* [7] = */ {
            /* name = */ "small box",
            /* vertTbl = */ {
                { 423.000000, 165.000000, 247.000000 },
                { 265.000000, 165.000000, 296.000000 },
                { 314.000000, 165.000000, 456.000000 },
                { 472.000000, 165.000000, 406.000000 },
                { 472.000000, 0.000000, 406.000000 },
                { 314.000000, 0.000000, 456.000000 },
                { 265.000000, 0.000000, 296.000000 },
                { 423.000000, 0.000000, 247.000000 }
            },
            /* vertClr = */ {
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
                { 0.0, 0.0, 0.5 },
            },
            /* vertUvw = */ {},
            /* quadTbl = */ {
                { 0, 1, 2, 3 },
                { 4, 3, 2, 5 },
                { 7, 0, 3, 4 },
                { 6, 1, 0, 7 },
                { 5, 2, 1, 6 },
                { 4, 5, 6, 7 }
            }
        },
    }
};
const Scene openSkyboxScene {
    /* name = */ "skybox",
    /* cam = */ {
        /* r = */ 1500.0,
        /* phi = */ 90.0,
        /* theta = */ 90.0,
        /* fov = */ 65.0,
        /* near = */ 1.0,
        /* far = */ 10000.0,
    },
    /* vars = */ {
        /* rMin = */ 10.0,
        /* rMax = */ 3000.0,
        /* worldTrans = */ { 0.0, 0.0, 0.0 },
        /* worldRot = */ { 0.0, 0.0, 0.0 },
        /* worldScale = */ { 1.0, 1.0, 1.0 },
    },
    /* meshes = */ {
        /* [0] = */ {
            /* name = */ "quad0",
            /* vertTbl = */ {
                { -500.0, -500.0, 0.0 },
                {  500.0, -500.0, 0.0 },
                {  500.0,  500.0, 0.0 },
                { -500.0,  500.0, 0.0 },
            },
            /* vertClr = */ {
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 },
            },
        },
        /* [1] = */ {
            /* name = */ "quad1",
            /* vertTbl = */ {
                {  500.0, -500.0, 0.0 },
                {  500.0, -500.0, 500.0 },
                {  500.0,  500.0, 500.0 },
                {  500.0,  500.0, 0.0 },
            },
            /* vertClr = */ {
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 },
            },
        },
        /* [2] = */ {
            /* name = */ "quad2",
            /* vertTbl = */ {
                {  -500.0, -500.0, 0.0 },
                {  -500.0,  500.0, 0.0 },
                {  -500.0,  500.0, 500.0 },
                {  -500.0, -500.0, 500.0 },
            },
            /* vertClr = */ {
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 },
            },
        },
        /* [3] = */ {
            /* name = */ "quad3",
            /* vertTbl = */ {
                {  -500.0, 500.0, 500.0 },
                {  -500.0, 500.0, 0.0 },
                {   500.0, 500.0, 0.0 },
                {   500.0, 500.0, 500.0 },
            },
            /* vertClr = */ {
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 },
            },
        },
        /* [4] = */ {
            /* name = */ "quad4",
            /* vertTbl = */ {
                {   500.0, -500.0, 500.0 },
                {   500.0, -500.0, 0.0 },
                {  -500.0, -500.0, 0.0 },
                {  -500.0, -500.0, 500.0 },
            },
            /* vertClr = */ {
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
                { 0.28, 0.36, 0.5 },
            },
            /* vertUvw = */ {},
            /* faces = */ {
                { 0, 1, 2, 3 },
            },
        },
    }
};

static float clearColor[] = { 0.0f, 0.0f, 0.0f, 1.0f };

static FogUniforms fogUniforms;

static void encoder(id <MTLRenderCommandEncoder> renderEncoder)
{
    static bool firstTime = true;
    if (firstTime) {
        fogUniforms.color = simd_make_float3(1.0, 1.0, 1.0);
        fogUniforms.density = 0.1;
        fogUniforms.scale = 256.0;
        fogUniforms.steps = 4;
        fogUniforms.wind = simd_make_float3(0, 0, 0);
        fogUniforms.heightMax = 256.0;
        firstTime = false;
    }
    [renderEncoder setFragmentBytes:&fogUniforms length:sizeof(FogUniforms) atIndex:1];
}

static void guiDraw()
{
    // fog gui
    ImGui::ColorEdit3("fog color", (float*) &fogUniforms.color);
    ImGui::SliderFloat("fog density", &fogUniforms.density, 0.0, 0.2);
    ImGui::SliderFloat("fog scale", &fogUniforms.scale, 1.0, 1024.0);
    ImGui::SliderInt("fog steps", &fogUniforms.steps, 1, 256);
    ImGui::InputFloat3("fog wind", (float*) &fogUniforms.wind);
    ImGui::InputFloat("fog height max", (float*) &fogUniforms.heightMax);
}

static const Sample sampleFog {
    /* sampleName = */ "fog",
    /* scenes = */ {
        /* [0] = */ &cornellBoxScene,
        /* [1] = */ &openSkyboxScene
    },
    /* vertexFunctionName = */ "sampleFogVertexShader",
    /* fragmentFunctionName = */ "sampleFogFragmentShader",
    /* clearColor = */ clearColor,
    /* encoderFunction = */ encoder,
    /* guiFunction = */ guiDraw,
};

const Sample* getSampleFog()
{
    return &sampleFog;
}
