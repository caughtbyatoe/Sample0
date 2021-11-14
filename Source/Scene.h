//
//  Scene.h
//  Sample0
//

#ifndef Types_h
#define Types_h

#include <string>
#include <vector>

struct VertexPosition
{
    float x;
    float y;
    float z;
};

struct VertexColor
{
    float r;
    float g;
    float b;
};

struct Face
{
    int p0;
    int p1;
    int p2;
    int p3;
};

struct QuadMesh
{
    std::string                 name;
    std::vector<VertexPosition> vertTbl;
    std::vector<VertexColor>    vertClr;
    std::vector<Face>           faces;
};

struct Camera
{
    float r;
    float phi;
    float theta;
    float fov;
    float near;
    float far;
};

struct Variables
{
    float rMax;
    float worldTrans[3];
    float worldRot[3];
    float worldScale[3];
};

struct Scene
{
    Camera cam;
    Variables vars;
    std::vector<QuadMesh> meshes;
};

const Scene& getSimpleQuadScene();
const Scene& getCornellBoxScene();
const Scene& getDefaultScene();
const char* getDefaultSceneName();
void setNextDefaultScene();

#endif /* Scene_h */
