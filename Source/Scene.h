// Copyright (c) 2021 caughtbyatoe
//
//  Scene.h
//  Sample0
//

#pragma once

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

struct VertexUvw
{
    float u;
    float v;
    float w;
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
    std::vector<VertexUvw>      vertUvw;
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
    float rMin;
    float rMax;
    float worldTrans[3];
    float worldRot[3];
    float worldScale[3];
};

struct Scene
{
    std::string name;
    Camera cam;
    Variables vars;
    std::vector<QuadMesh> meshes;
};


