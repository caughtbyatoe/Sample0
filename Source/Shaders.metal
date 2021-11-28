// Copyright (c) 2021 caughtbyatoe
//
//  Shaders.metal
//  Sample0
//
//

#include "Shaders.h"

#include <metal_stdlib>
using namespace metal;

// Vertex shader outputs and fragment shader inputs
struct VertexOut
{
    float4 position [[position]]; // in clip-space when returned from vertex function
    float4 color;
    float3 uvw;
};

vertex VertexOut
vertexShader(uint vertexID                      [[vertex_id]],
             constant Vertex *vertices          [[buffer(VertexInputIndexVertices)]],
             constant VertexData *vertData      [[buffer(VertexInputIndexVertexData)]],
             constant float4x4 *modelMatPointer [[buffer(VertexInputIndexModelMat)]],
             constant float4x4 *viewMatPointer  [[buffer(VertexInputIndexViewMat)]],
             constant float4x4 *projMatPointer  [[buffer(VertexInputIndexProjMat)]])
{
    VertexOut out;

    float4 worldP = float4(vertices[vertexID].position, 1.0);
    float4x4 modelMat = float4x4(*modelMatPointer);
    float4x4 viewMat = float4x4(*viewMatPointer);
    float4x4 projMat = float4x4(*projMatPointer);

    out.position = projMat * viewMat * modelMat * worldP;
    out.color = vertData[vertexID].color;
    out.uvw = vertData[vertexID].uvw;

    return out;
}

// ==-------------------------------------------------------------------------
// SampleVertexColor
// ==-------------------------------------------------------------------------
fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               constant SceneUniforms *sceneUniforms [[buffer(FragmentInputIndexSceneUniforms)]])
{
    return in.color;
}

// ==-------------------------------------------------------------------------
// SampleNoise
// ==-------------------------------------------------------------------------
// ==-------------------------------------------------------------------------
// == perlin noise
// ==   http://www.science-and-fiction.org/rendering/noise.html
// ==--------------------------------------------------------------------------

float rand3D(float3 co)
{
    return fract(sin(dot(co.xyz, float3(12.9898, 78.233, 144.7272))) * 43758.5453);
}

float simpleInterpolate(float a, float b, float x)
{
   return a + smoothstep(0.0, 1.0, x) * (b-a);
}

float interpolatedNoise3D(float x, float y, float z)
{
    float integerX = x - fract(x);
    float fractionalX = x - integerX;

    float integerY = y - fract(y);
    float fractionalY = y - integerY;

    float integerZ = z - fract(z);
    float fractionalZ = z - integerZ;

    float v1 = rand3D(float3(integerX, integerY, integerZ));
    float v2 = rand3D(float3(integerX + 1.0, integerY, integerZ));
    float v3 = rand3D(float3(integerX, integerY + 1.0, integerZ));
    float v4 = rand3D(float3(integerX + 1.0, integerY + 1.0, integerZ));

    float v5 = rand3D(float3(integerX, integerY, integerZ + 1.0));
    float v6 = rand3D(float3(integerX + 1.0, integerY, integerZ + 1.0));
    float v7 = rand3D(float3(integerX, integerY + 1.0, integerZ + 1.0));
    float v8 = rand3D(float3(integerX + 1.0, integerY + 1.0, integerZ + 1.0));

    float i1 = simpleInterpolate(v1, v5, fractionalZ);
    float i2 = simpleInterpolate(v2, v6, fractionalZ);
    float i3 = simpleInterpolate(v3, v7, fractionalZ);
    float i4 = simpleInterpolate(v4, v8, fractionalZ);

    float ii1 = simpleInterpolate(i1, i2, fractionalX);
    float ii2 = simpleInterpolate(i3, i4, fractionalX);

    return simpleInterpolate(ii1 , ii2, fractionalY);
}

float noise3D(float3 coord)
{
   return interpolatedNoise3D(coord.x, coord.y, coord.z);
}

// ==-------------------------------------------------------------------------
// == improved perlin noise
// ==   https://mrl.cs.nyu.edu/~perlin/paper445.pdf
// ==   https://mrl.cs.nyu.edu/~perlin/noise/
// ==-------------------------------------------------------------------------

float fade(float t) { return t * t * t * (t * (t * 6 - 15) + 10); }
float lerp(float t, float a, float b) { return a + t * (b - a); }
float grad(int hash, float x, float y, float z)
{
    int h = hash & 15;                      // CONVERT LO 4 BITS OF HASH CODE
    float u = h < 8 ? x : y,                 // INTO 12 GRADIENT DIRECTIONS.
    v = h < 4 ? y : h == 12 || h == 14 ? x : z;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
}

float noise(float x, float y, float z, constant int* p)
{
    int X = (int) floor(x) & 255;                  // FIND UNIT CUBE THAT
    int Y = (int) floor(y) & 255;                  // CONTAINS POINT.
    int Z = (int) floor(z) & 255;
    x -= floor(x);                                // FIND RELATIVE X,Y,Z
    y -= floor(y);                                // OF POINT IN CUBE.
    z -= floor(z);
    float u = fade(x);                                // COMPUTE FADE CURVES
    float v = fade(y);                                // FOR EACH OF X,Y,Z.
    float w = fade(z);
    int A = p[X  ] + Y;
    int AA = p[A] + Z;
    int AB = p[A + 1] + Z; // HASH COORDINATES OF
    int B = p[X + 1] + Y;
    int BA = p[B] + Z;
    int BB = p[B + 1] + Z;      // THE 8 CUBE CORNERS,

      return lerp(w, lerp(v, lerp(u, grad(p[AA  ], x  , y  , z   ),  // AND ADD
                                     grad(p[BA  ], x-1, y  , z   )), // BLENDED
                             lerp(u, grad(p[AB  ], x  , y-1, z   ),  // RESULTS
                                     grad(p[BB  ], x-1, y-1, z   ))),// FROM  8
                     lerp(v, lerp(u, grad(p[AA+1], x  , y  , z-1 ),  // CORNERS
                                     grad(p[BA+1], x-1, y  , z-1 )), // OF CUBE
                             lerp(u, grad(p[AB+1], x  , y-1, z-1 ),
                                     grad(p[BB+1], x-1, y-1, z-1 ))));
}
// ==-------------------------------------------------------------------------
// == Generic Gradient Noise:
// ==   https://www.iquilezles.org/www/articles/gradientnoise/gradientnoise.htm
// ==-------------------------------------------------------------------------
float gradNoise(float3 x)
{
    // grid
    float3 p = floor(x);
    float3 w = fract(x);
    
    // quintic interpolant
    float3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);

    // gradients
    float3 ga = rand3D(p + float3(0.0,0.0,0.0));
    float3 gb = rand3D(p + float3(1.0,0.0,0.0));
    float3 gc = rand3D(p + float3(0.0,1.0,0.0));
    float3 gd = rand3D(p + float3(1.0,1.0,0.0));
    float3 ge = rand3D(p + float3(0.0,0.0,1.0));
    float3 gf = rand3D(p + float3(1.0,0.0,1.0));
    float3 gg = rand3D(p + float3(0.0,1.0,1.0));
    float3 gh = rand3D(p + float3(1.0,1.0,1.0));
    
    // projections
    float va = dot(ga, w - float3(0.0,0.0,0.0));
    float vb = dot(gb, w - float3(1.0,0.0,0.0));
    float vc = dot(gc, w - float3(0.0,1.0,0.0));
    float vd = dot(gd, w - float3(1.0,1.0,0.0));
    float ve = dot(ge, w - float3(0.0,0.0,1.0));
    float vf = dot(gf, w - float3(1.0,0.0,1.0));
    float vg = dot(gg, w - float3(0.0,1.0,1.0));
    float vh = dot(gh, w - float3(1.0,1.0,1.0));
    
    // interpolation
    return va +
           u.x * (vb - va) +
           u.y * (vc - va) +
           u.z * (ve - va) +
           u.x * u.y * (va - vb - vc + vd) +
           u.y * u.z * (va - vc - ve + vg) +
           u.z * u.x * (va - vb - ve + vf) +
           u.x * u.y * u.z * (-va + vb + vc - vd + ve - vf - vg + vh);
}

// == -------------------------------------------------------------------------

float evaluateNoise(float3 pos, constant ShaderUniforms *shaderUniforms, constant int *newPerlinP)
{
    float result = 0;
    switch (shaderUniforms->noiseType) {
        case NoiseTypePerlin:
            result = noise3D(pos);
            break;
        case NoiseTypeNewPerlin:
            result = noise(pos.x, pos.y, pos.z, newPerlinP);
            break;
        case NoiseTypeGradient:
        default:
            result = gradNoise(pos);
            break;
    }
    if (shaderUniforms->useTurbulence) {
        result = fabs(2.0 * result - 1.0);
    }
    return result;
}

fragment float4 sampleNoiseFragmentShader(VertexOut in [[stage_in]],
                                          constant SceneUniforms *sceneUniforms [[buffer(FragmentInputIndexSceneUniforms)]],
                                          constant ShaderUniforms *shaderUniforms [[buffer(1)]],
                                          constant int *newPerlinP [[buffer(2)]])
{
    float4 result;

    switch (shaderUniforms->patternType) {
        case PatternTypeUvw:
            result = float4(in.uvw, 1.0);
            break;
        case PatternTypeRandom:
        {
            float r = rand3D(in.uvw * shaderUniforms->uvwScale);
            result = float4(r, r, r, 1.0);
            break;
        }
        case PatternTypeNoise:
        {
            const float3 P = shaderUniforms->uvwScale * (in.uvw + float3(0.0, 0.0, shaderUniforms->zOffset));
            const float f = pow(2.0, shaderUniforms->octaves - 1);
            const float a = pow(0.5, shaderUniforms->octaves - 1);
            float r = a * evaluateNoise(P * f, shaderUniforms, newPerlinP);
            result = float4(r, r, r, 1.0);
            break;
        }
        case PatternTypeFbm:
        {
            const float3 P = shaderUniforms->uvwScale * (in.uvw + float3(0.0, 0.0, shaderUniforms->zOffset));
            float f = 1.0;
            float a = 0.5;
            float r = 0;
            for (int i = 0; i < shaderUniforms->octaves; ++i) {
                r += a * evaluateNoise(P * f, shaderUniforms, newPerlinP);
                f *= 2.0;
                a *= 0.5;
            }
            result = float4(r, r, r, 1.0);
            break;
        }
        default:
            result = in.color;
    }

    return result;
}

// ==-------------------------------------------------------------------------
// == Sample Fog
// ==-------------------------------------------------------------------------
// Vertex shader outputs and fragment shader inputs
struct VertexOutFog
{
    float4 position [[position]]; // in clip-space when returned from vertex function
    float4 color;
    float3 pos; // fragment position in world space
};

vertex VertexOutFog
sampleFogVertexShader(uint vertexID                      [[vertex_id]],
                      constant Vertex *vertices          [[buffer(VertexInputIndexVertices)]],
                      constant VertexData *vertData      [[buffer(VertexInputIndexVertexData)]],
                      constant float4x4 *modelMatPointer [[buffer(VertexInputIndexModelMat)]],
                      constant float4x4 *viewMatPointer  [[buffer(VertexInputIndexViewMat)]],
                      constant float4x4 *projMatPointer  [[buffer(VertexInputIndexProjMat)]])
{
    VertexOutFog out;

    float4 objP = float4(vertices[vertexID].position, 1.0);
    float4x4 modelMat = float4x4(*modelMatPointer);
    float4x4 viewMat = float4x4(*viewMatPointer);
    float4x4 projMat = float4x4(*projMatPointer);

    out.pos = (modelMat * objP).xyz;
    out.position = projMat * viewMat * float4(out.pos, 1.0);
    out.color = vertData[vertexID].color;

    return out;
}

fragment float4 sampleFogFragmentShader(VertexOutFog in [[stage_in]],
                                        constant SceneUniforms *sceneUniforms [[buffer(FragmentInputIndexSceneUniforms)]],
                                        constant FogUniforms *fogUniforms [[buffer(1)]])
{
    const float3 ray = in.pos - sceneUniforms->eyePos;
    const int numSteps = fogUniforms->steps;
    const float3 step = ray / numSteps;
    float accum = 0.0;
    for (int i = 0; i < numSteps; ++i) {
        const float3 P = in.pos - i * step;
        const float baseNoiseScale = 1.0f / fogUniforms->scale;
        const float3 windOffset = fogUniforms->wind * sceneUniforms->frame;
        const float grad = max(0.0, 1.0 - max(0.0, P.y / fogUniforms->heightMax));
        accum += grad * noise3D((P + windOffset) * baseNoiseScale);
    }
    accum /= numSteps;
    const float distance = length(ray);
    const float T = 1.0 / exp(pow(fogUniforms->density, 3.0) * accum * distance);

    const float3 fogColor = fogUniforms->color;
    const float3 surfaceColor(in.color.rgb);
    return float4(mix(fogColor, surfaceColor, float3(T)), 1.0);
}
