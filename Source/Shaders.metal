//
//  Shaders.metal
//  Sample0
//
//

#include "Shaders.h"

#include <metal_stdlib>
using namespace metal;

// Vertex shader outputs and fragment shader inputs
struct VertexData
{
    float4 position [[position]]; // in clip-space when returned from vertex function
    float4 color;
};

vertex VertexData
vertexShader(uint vertexID                      [[vertex_id]],
             constant Vertex *vertices          [[buffer(VertexInputIndexVertices)]],
             constant float4x4 *modelMatPointer [[buffer(VertexInputIndexModelMat)]],
             constant float4x4 *viewMatPointer  [[buffer(VertexInputIndexViewMat)]],
             constant float4x4 *projMatPointer  [[buffer(VertexInputIndexProjMat)]])
{
    VertexData out;

    float4 worldP = float4(vertices[vertexID].position, 1.0);
    float4x4 modelMat = float4x4(*modelMatPointer);
    float4x4 viewMat = float4x4(*viewMatPointer);
    float4x4 projMat = float4x4(*projMatPointer);

    out.position = projMat * viewMat * modelMat * worldP;
    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentShader(VertexData in [[stage_in]])
{
    return in.color;
}
