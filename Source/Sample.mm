//  Copyright (c) 2021 caughtbyatoe
//
//  Sample.mm
//  Sample0
//
//

#include "Sample.h"

#include "SampleFog.h"
#include "SampleNoise.h"
#include "SampleVertexColor.h"


enum class Samples {
    VertexColor = 0,
    Noise,
    Fog,
    NUM_SAMPLES
};

const Sample *getNextSample()
{
    static Samples current = static_cast<Samples>(static_cast<int>(Samples::NUM_SAMPLES) - 1);
    current = static_cast<Samples>((static_cast<int>(current) + 1) % static_cast<int>(Samples::NUM_SAMPLES));

    const Sample *result = nullptr;

    switch (current) {
        case Samples::VertexColor:
            result = getSampleVertexColor();
            break;
        case Samples::Noise:
            result = getSampleNoise();
            break;
        case Samples::Fog:
            result = getSampleFog();
            break;
        default:
        case Samples::NUM_SAMPLES:
            break;
    }

    return result;
}
