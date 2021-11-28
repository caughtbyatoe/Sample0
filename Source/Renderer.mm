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
#include "Sample.h"
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
    const Sample* _sample;
    Scene _scene;
    int _sceneIndex;
    SceneUniforms _sceneUniforms;
    std::vector<Vertex> _triangleVertexBuffer;
    std::vector<VertexData> _triangleVertexData;
}

- (void)loadScene
{
    // We render using vert colors and triangle soup
    _scene = *_sample->scenes[_sceneIndex];
    size_t numTris = 0;
    for (QuadMesh& mesh : _scene.meshes) {
        numTris += mesh.faces.size() * 2;
    }
    _triangleVertexBuffer.clear();
    _triangleVertexBuffer.reserve(numTris);
    _triangleVertexData.clear();
    _triangleVertexData.reserve(numTris);
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
            // default uvs are probably not what you want
            const VertexUvw uv0 = mesh.vertUvw.size() ? mesh.vertUvw[face.p0] : VertexUvw { 0.0, 0.0, 0.0 };
            const VertexUvw uv1 = mesh.vertUvw.size() ? mesh.vertUvw[face.p1] : VertexUvw { 1.0, 0.0, 0.0 };
            const VertexUvw uv2 = mesh.vertUvw.size() ? mesh.vertUvw[face.p2] : VertexUvw { 1.0, 1.0, 0.0 };
            const VertexUvw uv3 = mesh.vertUvw.size() ? mesh.vertUvw[face.p3] : VertexUvw { 0.0, 1.0, 0.0 };
            const Vertex v0 = { { p0.x, p0.y, p0.z} };
            const Vertex v1 = { { p1.x, p1.y, p1.z} };
            const Vertex v2 = { { p2.x, p2.y, p2.z} };
            const Vertex v3 = { { p3.x, p3.y, p3.z} };
            const VertexData d0 = { { c0.r, c0.g, c0.b, 1.0 }, { uv0.u, uv0.v, uv0.w } };
            const VertexData d1 = { { c1.r, c1.g, c1.b, 1.0 }, { uv1.u, uv1.v, uv1.w } };
            const VertexData d2 = { { c2.r, c2.g, c2.b, 1.0 }, { uv2.u, uv2.v, uv2.w } };
            const VertexData d3 = { { c3.r, c3.g, c3.b, 1.0 }, { uv3.u, uv3.v, uv3.w } };
            // tri 1
            _triangleVertexBuffer.push_back(v0);
            _triangleVertexBuffer.push_back(v1);
            _triangleVertexBuffer.push_back(v3);
            _triangleVertexData.push_back(d0);
            _triangleVertexData.push_back(d1);
            _triangleVertexData.push_back(d3);
            // tri 2
            _triangleVertexBuffer.push_back(v3);
            _triangleVertexBuffer.push_back(v1);
            _triangleVertexBuffer.push_back(v2);
            _triangleVertexData.push_back(d3);
            _triangleVertexData.push_back(d1);
            _triangleVertexData.push_back(d2);
        }
    }
}

- (void)makePipeline:(MTKView *)mtkView
{
    NSString* vertexFunctionName = [NSString stringWithUTF8String:_sample->vertexFunctionName];
    NSString* fragmentFunctionName = [NSString stringWithUTF8String:_sample->fragmenFunctionName];

    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:vertexFunctionName];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:fragmentFunctionName];
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
}

- (nonnull instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if (self) {
        _device = mtkView.device;
        _sample = getNextSample();
        _sceneIndex = 0;

        mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
        mtkView.clearDepth = 1.0;

        [self makePipeline:mtkView];
        
        MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
        depthDescriptor.depthCompareFunction = MTLCompareFunctionLess;
        depthDescriptor.depthWriteEnabled = YES;
        _depthState = [_device newDepthStencilStateWithDescriptor:depthDescriptor];
        NSAssert(_depthState, @"Failed to create depth state");

        _sceneUniforms.eyePos = simd_make_float3(0, 0, 0);
        _sceneUniforms.frame = 0;

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

static float3 computeCameraLocation(float r, float phi, float theta)
{
    const float cosPhi = cosf(phi * M_PI / 180.0f);
    const float sinPhi = sinf(phi * M_PI / 180.0f);
    const float cosTheta = cosf(theta * M_PI / 180.0f);
    const float sinTheta = sinf(theta * M_PI / 180.0f);
    const float3 eye { r * sinTheta * cosPhi, r * cosTheta, r * sinTheta * sinPhi };
    return eye;
}

static float4x4 computeOrbitViewMat(float3 eye)
{
    const float3 target { 0.0f, 0.0f, 0.0f };
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

    const float *clearColor = _sample->clearColor;

    float& r = _scene.cam.r;
    float& phi = _scene.cam.phi;
    float& theta = _scene.cam.theta;
    float4x4 viewMat {
        (float4) { 1.0f,  0.0f, 0.0f, 0.0f },
        (float4) { 0.0f,  1.0f, 0.0f, 0.0f },
        (float4) { 0.0f,  0.0f, 1.0f, 0.0f },
        (float4) { 0.0f,  0.0f, -r,   1.0f }
    };
    _sceneUniforms.eyePos = computeCameraLocation(r, phi, theta);
    ++_sceneUniforms.frame;
    viewMat = computeOrbitViewMat(_sceneUniforms.eyePos);
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
    
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(clearColor[0] * clearColor[3], clearColor[1] * clearColor[3], clearColor[2] * clearColor[3], clearColor[3]);
    
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

    const VertexData* triangleData = _triangleVertexData.data();
    const size_t numData = _triangleVertexData.size();
    const size_t sizeofTriangleData = numData * sizeof(VertexData);

    [renderEncoder setVertexBytes:triangleData
                           length:sizeofTriangleData
                          atIndex:VertexInputIndexVertexData];

    [renderEncoder setFragmentBytes:&_sceneUniforms length:sizeof(SceneUniforms) atIndex:FragmentInputIndexSceneUniforms];
    
    // call sample specific encoder
    _sample->encoderFunction(renderEncoder);
    
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

    ImGui::SliderFloat("Camera R", &r, _scene.vars.rMin, _scene.vars.rMax);
    ImGui::SliderFloat("Camera phi", &phi, 0.0, 359.0);
    ImGui::SliderFloat("Camera theta", &theta, 0.0, 180.0);
    if (ImGui::Button("Reset Camera")) {
        _scene.cam = _sample->scenes[_sceneIndex]->cam;
    }

    ImGui::InputFloat3("World Translation", tran);
    ImGui::InputFloat3("World Rotation", rot);
    ImGui::InputFloat3("World Scale", scale);
    if (ImGui::Button("Reset World")) {
        manipMode = MANIP_NONE;
        for (int i = 0; i < 3; ++i) {
            tran[i] = _sample->scenes[_sceneIndex]->vars.worldTrans[i];
            rot[i] = _sample->scenes[_sceneIndex]->vars.worldRot[i];
            scale[i] = _sample->scenes[_sceneIndex]->vars.worldScale[i];
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
    ImGui::Text("Current Sample: %s", _sample->sampleName);
    bool nextSample = false;
    if (ImGui::Button("Next Sample")) {
        nextSample = true;
    }
    ImGui::Text("Current Scene: %s", _scene.name.c_str());
    if (ImGui::Button("Next Scene")) {
        _sceneIndex = (_sceneIndex + 1) % _sample->scenes.size();
        [self loadScene];
    }
    
    // call sample specific gui
    _sample->guiFunction();

    ImGui::Render();
    ImDrawData *drawData = ImGui::GetDrawData();
    ImGui_ImplMetal_RenderDrawData(drawData, commandBuffer, renderEncoder);
    
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:view.currentDrawable];

    [commandBuffer commit];
    
    if (nextSample) {
        _sample = getNextSample();
        _sceneIndex = 0;
        [self makePipeline:view];
        [self loadScene];
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}
@end
