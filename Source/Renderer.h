//
//  Renderer.h
//  Sample0
//
//

#ifndef Renderer_h
#define Renderer_h

#include <MetalKit/MetalKit.h>

@interface Renderer : NSObject<MTKViewDelegate>

- (nonnull instancetype) initWithMetalKitView:(nonnull MTKView *) mtkView;

@end

#endif /* Renderer_h */
