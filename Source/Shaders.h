//
//  Shaders.h
//  Sample0
//
//

// included by both metal and obj-c source files

#ifndef Shaders_h
#define Shaders_h

#include <simd/simd.h>

using simd::float3;
using simd::float4;

typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
    VertexInputIndexModelMat     = 1,
    VertexInputIndexViewMat      = 2,
    VertexInputIndexProjMat      = 3,
} VertexInputIndex;

typedef struct
{
    float3 position;
    float4 color;
} Vertex;

#endif /* Shaders_h */
