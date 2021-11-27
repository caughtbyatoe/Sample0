// Copyright (c) 2021 caughtbyatoe
//
//  Renderer.mm
//  Sample0
//
//
#include "Renderer.h"

#include "ImGui/imgui.h"
#include "ImGui/imgui_impl_metal.h"
#include "ImGui/imgui_impl_osx.h"
#include "ImGui/ImGuizmo.h"
#include "Scene.h"
#include "Shaders.h"

#include <vector>

using simd::float4x4;

@implementation Renderer
{
    id<MTLDevice> _device;
    id<MTLRenderPipelineState> _pipeline;
    id<MTLCommandQueue> _commandQueue;
    id<MTLDepthStencilState> _depthState;
    Scene _scene;
    std::vector<Vertex> _triangleVertexBuffer;
}

- (void)loadScene
{
    // We render using vert colors and triangle soup
    _scene = getDefaultScene();
    size_t numTris = 0;
    for (QuadMesh& mesh : _scene.meshes) {
        numTris += mesh.faces.size() * 2;
    }
    _triangleVertexBuffer.clear();
    _triangleVertexBuffer.reserve(numTris);
    for (QuadMesh& mesh : _scene.meshes) {
        for (Face& face : mesh.faces) {
            const VertexPosition p0 = mesh.vertTbl[face.p0];
            const VertexPosition p1 = mesh.vertTbl[face.p1];
            const VertexPosition p2 = mesh.vertTbl[face.p2];
            const VertexPosition p3 = mesh.vertTbl[face.p3];
            const VertexColor c0 = mesh.vertClr[face.p0];
            const VertexColor c1 = mesh.vertClr[face.p1];
            const VertexColor c2 = mesh.vertClr[face.p2];
            const VertexColor c3 = mesh.vertClr[face.p3];
            const Vertex v0 = { { p0.x, p0.y, p0.z}, { c0.r, c0.g, c0.b, 1.0 } };
            const Vertex v1 = { { p1.x, p1.y, p1.z}, { c1.r, c1.g, c1.b, 1.0 } };
            const Vertex v2 = { { p2.x, p2.y, p2.z}, { c2.r, c2.g, c2.b, 1.0 } };
            const Vertex v3 = { { p3.x, p3.y, p3.z}, { c3.r, c3.g, c3.b, 1.0 } };
            // tri 1
            _triangleVertexBuffer.push_back(v0);
            _triangleVertexBuffer.push_back(v1);
            _triangleVertexBuffer.push_back(v3);
            // tri 2
            _triangleVertexBuffer.push_back(v3);
            _triangleVertexBuffer.push_back(v1);
            _triangleVertexBuffer.push_back(v2);
        }
    }
}

- (nonnull instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if (self) {
        _device = mtkView.device;

        mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
        mtkView.clearDepth = 1.0;

        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        // Configure a pipeline descriptor that is used to create a pipeline state.
        MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineDescriptor.vertexFunction = vertexFunction;
        pipelineDescriptor.fragmentFunction = fragmentFunction;
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
        NSError *error = nil;
        _pipeline = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor
                                                            error:&error];
        NSAssert(_pipeline, @"Failed to create pipeline: %@", error);
        
        MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
        depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthDescriptor.depthWriteEnabled = YES;
        _depthState = [_device newDepthStencilStateWithDescriptor:depthDescriptor];
        NSAssert(_depthState, @"Failed to create depth state");

        _commandQueue = [_device newCommandQueue];
        
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGuiIO& io = ImGui::GetIO(); (void)io;

        // Setup Renderer backend
        ImGui_ImplMetal_Init(_device);
        
        // Load a scene
        [self loadScene];
    }
    return self;
}

static float4x4 computePerspectiveProjection(float fovDegrees, float aspect, float near, float far)
{
    const float n = near;
    const float f = far;
    const float t = tan(fovDegrees * 0.5 * M_PI / 180.0f) * n;
    const float r = aspect * t;
    const float l = -r;
    const float b = -t;

    const float4x4 m {
        (float4) { 2.0f * n / (r - l), 0.0f              ,   0.0f                  ,  0.0f },
        (float4) { 0.0f              , 2.0f * n / (t - b),   0.0f                  ,  0.0f },
        (float4) { (r + l) / (r - l) , (t + b) / (t - b) ,  -f / (f - n)           , -1.0f },
        (float4) { 0.0f              , 0.0f              ,  -f * n / (f - n)       ,  0.0f }
    };

    return m;
}

static float4x4 lookAt(float3 eye, float3 target, float3 up)
{
    const float3 z = simd_normalize(eye - target);
    const float3 x = simd_normalize(simd_cross(up, z));
    const float3 y = simd_cross(z, x);
    const float4x4 rInv = {
        float4 { x.x, y.x, z.x, 0.0f },
        float4 { x.y, y.y, z.y, 0.0f },
        float4 { x.z, y.z, z.z, 0.0f },
        float4 { 0.0f, 0.0f, 0.0f, 1.0f }
    };
    
    const float4x4 tInv = {
        float4 { 1.0f, 0.0f, 0.0f, 0.0f },
        float4 { 0.0f, 1.0f, 0.0f, 0.0f },
        float4 { 0.0f, 0.0f, 1.0f, 0.0f },
        float4 { -eye.x, -eye.y, -eye.z, 1.0f },
    };
    
    return rInv * tInv;
}

static float4x4 computeOrbitViewMat(float r, float phi, float theta)
{
    const float3 target { 0.0f, 0.0f, 0.0f };
    const float cosPhi = cosf(phi * M_PI / 180.0f);
    const float sinPhi = sinf(phi * M_PI / 180.0f);
    const float cosTheta = cosf(theta * M_PI / 180.0f);
    const float sinTheta = sinf(theta * M_PI / 180.0f);
    const float3 eye { r * sinTheta * cosPhi, r * cosTheta, r * sinTheta * sinPhi };
    const float3 up { 0.0f, 1.0f, 0.0f };
    return lookAt(eye, target, up);
}

static float4x4 computeModelMatrix(const float *tran, const float *rot, const float *scale)
{
    float4x4 m;
    ImGuizmo::RecomposeMatrixFromComponents(tran, rot, scale, (float*)&m);
    return m;
}

- (void)drawInMTKView:(MTKView *)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
#if TARGET_OS_OSX
    CGFloat framebufferScale = view.window.screen.backingScaleFactor ?: NSScreen.mainScreen.backingScaleFactor;
#else
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
#endif
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    static float clear_color[4] = { 0.28f, 0.36f, 0.5f, 1.0f };

    float& r = _scene.cam.r;
    float& phi = _scene.cam.phi;
    float& theta = _scene.cam.theta;
    float4x4 viewMat {
        (float4) { 1.0f,  0.0f, 0.0f, 0.0f },
        (float4) { 0.0f,  1.0f, 0.0f, 0.0f },
        (float4) { 0.0f,  0.0f, 1.0f, 0.0f },
        (float4) { 0.0f,  0.0f, -r,   1.0f }
    };
    viewMat = computeOrbitViewMat(r, phi, theta);
    const float fov = _scene.cam.fov;
    const float near = _scene.cam.near;
    const float far = _scene.cam.far;
    const float aspect = float(view.bounds.size.width) / float(view.bounds.size.height);
    float4x4 projMat = computePerspectiveProjection(fov, aspect, near, far);

    float *tran = _scene.vars.worldTrans;
    float *rot = _scene.vars.worldRot;
    float *scale = _scene.vars.worldScale;
    float4x4 modelMat = computeModelMatrix(tran, rot, scale);
    
    enum ManipMode {
        MANIP_NONE,
        MANIP_TRANS,
        MANIP_ROT,
        MANIP_SCALE
    };
    static int manipMode = MANIP_NONE;
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (!renderPassDescriptor) return;
    
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clear_color[0] * clear_color[3], clear_color[1] * clear_color[3], clear_color[2] * clear_color[3], clear_color[3]);
    
    id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    // Set the region of the drawable to draw into.
    // NOTE: near and far are expressed in NDC coordinates
    const double width  = view.bounds.size.width;
    const double height = view.bounds.size.height;
    [renderEncoder setViewport:(MTLViewport) { 0.0, 0.0, framebufferScale * width, framebufferScale * height, 0.0, 1.0 }];
    
    [renderEncoder setRenderPipelineState:_pipeline];
    [renderEncoder setDepthStencilState:_depthState];

    [renderEncoder setVertexBytes:&modelMat
                           length:sizeof(modelMat)
                          atIndex:VertexInputIndexModelMat];

    [renderEncoder setVertexBytes:&viewMat
                           length:sizeof(viewMat)
                          atIndex:VertexInputIndexViewMat];

    [renderEncoder setVertexBytes:&projMat
                           length:sizeof(projMat)
                          atIndex:VertexInputIndexProjMat];

    const Vertex* triangleVertices = _triangleVertexBuffer.data();
    const size_t numVerts = _triangleVertexBuffer.size();
    const size_t sizeofTriangleVertices = numVerts * sizeof(Vertex);

    [renderEncoder setVertexBytes:triangleVertices
                           length:sizeofTriangleVertices
                          atIndex:VertexInputIndexVertices];
    
    
    // Draw the triangles
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:numVerts];

    // Draw the Gui
    ImGui_ImplMetal_NewFrame(renderPassDescriptor);
#if TARGET_OS_OSX
    ImGui_ImplOSX_NewFrame(view);
#endif
    ImGui::NewFrame();
    ImGuizmo::BeginFrame();
    ImGuizmo::SetOrthographic(false);
    ImGuizmo::SetRect(0, 0, width, height);

    ImGui::SliderFloat("Camera R", &r, 0.5, _scene.vars.rMax);
    ImGui::SliderFloat("Camera phi", &phi, 0.0, 359.0);
    ImGui::SliderFloat("Camera theta", &theta, 0.0, 180.0);
    if (ImGui::Button("Reset Camera")) {
        _scene.cam = getDefaultScene().cam;
    }

    ImGui::InputFloat3("World Translation", tran);
    ImGui::InputFloat3("World Rotation", rot);
    ImGui::InputFloat3("World Scale", scale);
    if (ImGui::Button("Reset World")) {
        manipMode = MANIP_NONE;
        for (int i = 0; i < 3; ++i) {
            tran[i] = getDefaultScene().vars.worldTrans[i];
            rot[i] = getDefaultScene().vars.worldRot[i];
            scale[i] = getDefaultScene().vars.worldScale[i];
        }
    }
    ImGui::RadioButton("No Manipulator", &manipMode, MANIP_NONE);
    ImGui::RadioButton("Transation", &manipMode, MANIP_TRANS);
    ImGui::RadioButton("Rotation", &manipMode, MANIP_ROT);
    ImGui::RadioButton("Scale", &manipMode, MANIP_SCALE);
    if (manipMode != MANIP_NONE) {
        ImGuizmo::OPERATION op = ImGuizmo::TRANSLATE;
        if (manipMode == MANIP_ROT)   op = ImGuizmo::ROTATE;
        if (manipMode == MANIP_SCALE) op = ImGuizmo::SCALE;
        ImGuizmo::MODE mode = ImGuizmo::LOCAL;
        ImGuizmo::Manipulate((const float*)&viewMat, (const float*)&projMat, op, mode, (float*)&modelMat);
        ImGuizmo::DecomposeMatrixToComponents((const float*)&modelMat, tran, rot, scale);
    }
    ImGui::Text("Current Scene: %s", getDefaultSceneName());
    if (ImGui::Button("Next Scene")) {
        setNextDefaultScene();
        [self loadScene];
    }

    ImGui::Render();
    ImDrawData *drawData = ImGui::GetDrawData();
    ImGui_ImplMetal_RenderDrawData(drawData, commandBuffer, renderEncoder);
    
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:view.currentDrawable];

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}
@end
