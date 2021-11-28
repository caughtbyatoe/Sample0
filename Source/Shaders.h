// Copyright (c) 2021 caughtbyatoe
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
    VertexInputIndexVertexData   = 4,
} VertexInputIndex;

typedef struct
{
    float3 position;
} Vertex;

typedef struct
{
    float4 color;
    float3 uvw;
} VertexData;

typedef struct
{
    float3 eyePos; // in world space
    int frame;
} SceneUniforms;

typedef enum FragmentInputIndex
{
    FragmentInputIndexSceneUniforms = 0,
} FragmentInputIndex;

// ==-------------------------------------------------------------------------
// == SampleNoise
// ==-------------------------------------------------------------------------
typedef enum PatternType
{
    PatternTypeUvw = 0,
    PatternTypeRandom,
    PatternTypeNoise,
    PatternTypeFbm
} PatternType;

typedef enum NoiseType
{
    NoiseTypePerlin = 0,
    NoiseTypeNewPerlin,
    NoiseTypeGradient
} NoiseType;

typedef struct
{
    float3 uvwScale;
    float zOffset;
    int octaves;
    int patternType;
    int noiseType;
    int useTurbulence;
} ShaderUniforms;

// ==-------------------------------------------------------------------------
// == Sample Fog
// ==-------------------------------------------------------------------------
typedef struct
{
    float3 color;
    float density;
    float scale;
    int steps;
    float3 wind;
    float heightMax;
} FogUniforms;



#endif /* Shaders_h */
