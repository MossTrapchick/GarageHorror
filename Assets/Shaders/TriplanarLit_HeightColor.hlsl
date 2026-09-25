#ifndef TRIPLANAR_LIT_INCLUDED
#define TRIPLANAR_LIT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


// ============================================================
// Custom textures
// ============================================================
//
// BaseMap, BumpMap, MetallicGlossMap and OcclusionMap
// are already declared by URP LitInput.hlsl.
//
// Only custom HeightMap is declared here.
//

TEXTURE2D(_HeightMap);
SAMPLER(sampler_HeightMap);


// ============================================================
// Custom material parameters
// ============================================================

float _HeightStrength;
float _HeightSteps;

float4 _HeightColor;
float _HeightColorStrength;
float _HeightColorThreshold;
float _HeightColorSmoothness;

float4 _TriplanarTiling;
float4 _TriplanarOffset;

float _TriplanarBlendSharpness;


// ============================================================
// Utility
// ============================================================

float3 TriplanarSafeNormalize(float3 v)
{
    float lenSq = dot(v, v);

    return v * rsqrt(max(lenSq, 1e-8));
}


// ============================================================
// Triplanar weights
// ============================================================

float3 GetTriplanarWeights(float3 normalWS)
{
    float3 weights = abs(normalWS);

    weights = pow(
        saturate(weights),
        _TriplanarBlendSharpness
    );

    float sumWeights =
        weights.x +
        weights.y +
        weights.z;

    return weights / max(sumWeights, 1e-5);
}


// ============================================================
// Base triplanar UV
// ============================================================

void GetTriplanarUV(
    float3 positionWS,
    float3 normalWS,
    out float2 uvX,
    out float2 uvY,
    out float2 uvZ)
{
    float2 tiling =
        _TriplanarTiling.xy;

    float2 offset =
        _TriplanarOffset.xy;

    float signX =
        normalWS.x >= 0.0 ? 1.0 : -1.0;

    float signY =
        normalWS.y >= 0.0 ? 1.0 : -1.0;

    float signZ =
        normalWS.z >= 0.0 ? 1.0 : -1.0;


    // X projection
    uvX = float2(
        positionWS.z * signX,
        positionWS.y
    );


    // Y projection
    uvY = float2(
        positionWS.x,
        positionWS.z * signY
    );


    // Z projection
    uvZ = float2(
        positionWS.x * signZ,
        positionWS.y
    );


    uvX =
        uvX * tiling +
        offset;

    uvY =
        uvY * tiling +
        offset;

    uvZ =
        uvZ * tiling +
        offset;
}


// ============================================================
// Height sampling
// ============================================================

float SampleHeight(float2 uv)
{
    return SAMPLE_TEXTURE2D(
        _HeightMap,
        sampler_HeightMap,
        uv
    ).r;
}


// ============================================================
// Height color mask
// ============================================================

float GetHeightColorMask(float2 uv)
{
    if (_HeightColorStrength <= 0.00001)
        return 0.0;

    float height = SampleHeight(uv);

    float halfWidth =
        max(_HeightColorSmoothness, 0.001);

    float mask = smoothstep(
        _HeightColorThreshold - halfWidth,
        _HeightColorThreshold + halfWidth,
        height
    );

    return saturate(
        mask * _HeightColorStrength
    );
}


float GetTriplanarHeightColorMask(
    float2 uvX,
    float2 uvY,
    float2 uvZ,
    float3 weights)
{
    float maskX =
        GetHeightColorMask(uvX);

    float maskY =
        GetHeightColorMask(uvY);

    float maskZ =
        GetHeightColorMask(uvZ);

    return saturate(
        maskX * weights.x +
        maskY * weights.y +
        maskZ * weights.z
    );
}


// ============================================================
// Parallax Occlusion Mapping
// ============================================================
//
// IMPORTANT:
// The tangent / bitangent basis here is intentionally identical
// to the basis used by the triplanar normal reconstruction.
//
// This keeps POM and normal mapping in exactly the same
// projection coordinate system.
//

float2 ParallaxOcclusionMapping(
    float2 uv,
    float2 viewPlane,
    float viewNormal)
{
    if (_HeightStrength <= 0.00001)
        return uv;


    // If the surface is viewed from behind this projection,
    // don't perform POM in this projection.
    //
    // Using abs(viewNormal) here causes the parallax direction
    // to flip when the object/view relationship changes.
    if (viewNormal <= 0.001)
        return uv;


    float safeViewNormal =
        max(viewNormal, 0.08);


    float2 parallaxDirection =
        viewPlane / safeViewNormal;


    float layerCount =
        clamp(
            _HeightSteps,
            2.0,
            32.0
        );


    float layerDepth =
        1.0 / layerCount;


    float2 uvStep =
        parallaxDirection *
        (_HeightStrength / layerCount);


    float2 currentUV =
        uv;


    float currentLayerDepth =
        0.0;


    float currentHeight =
        SampleHeight(currentUV);


    float previousLayerDepth =
        0.0;


    float previousHeight =
        currentHeight;


    [loop]
    for (int i = 0; i < 32; i++)
    {
        if ((float) i >= layerCount)
            break;

        if (currentLayerDepth >= currentHeight)
            break;


        previousLayerDepth =
            currentLayerDepth;

        previousHeight =
            currentHeight;


        currentUV += uvStep;

        currentLayerDepth +=
            layerDepth;

        currentHeight =
            SampleHeight(currentUV);
    }


    float after =
        currentHeight -
        currentLayerDepth;


    float before =
        previousHeight -
        previousLayerDepth;


    float interpolation =
        after /
        max(
            after - before,
            1e-5
        );


    interpolation =
        saturate(interpolation);


    float2 finalUV =
        lerp(
            currentUV,
            currentUV - uvStep,
            interpolation
        );


    return finalUV;
}


// ============================================================
// POM - X projection
// ============================================================

float2 GetParallaxUV_X(
    float2 uv,
    float3 viewDirWS,
    float3 geometryNormalWS)
{
    float signX =
        geometryNormalWS.x >= 0.0
        ? 1.0
        : -1.0;


    // UV mapping:
    //
    // U =  Z * signX
    // V =  Y
    //
    // Therefore:
    // Tangent   =  Z * signX
    // Bitangent = -Y
    // Normal    =  X * signX
    //
    // T x B = N
    //

    float3 projectionNormal =
        float3(
            signX,
            0.0,
            0.0
        );


    float3 tangent =
        float3(
            0.0,
            0.0,
            signX
        );


    float3 bitangent =
        float3(
            0.0,
            -1.0,
            0.0
        );


    float viewNormal =
        dot(
            viewDirWS,
            projectionNormal
        );


    float viewU =
        dot(
            viewDirWS,
            tangent
        );


    float viewV =
        dot(
            viewDirWS,
            bitangent
        );


    return ParallaxOcclusionMapping(
        uv,
        float2(viewU, viewV),
        viewNormal
    );
}


// ============================================================
// POM - Y projection
// ============================================================

float2 GetParallaxUV_Y(
    float2 uv,
    float3 viewDirWS,
    float3 geometryNormalWS)
{
    float signY =
        geometryNormalWS.y >= 0.0
        ? 1.0
        : -1.0;


    // UV mapping:
    //
    // U = X
    // V = Z * signY
    //
    // Tangent   = X
    // Bitangent = Z * signY
    // Normal    = Y * signY
    //
    // T x B = N
    //

    float3 projectionNormal =
        float3(
            0.0,
            signY,
            0.0
        );


    float3 tangent =
        float3(
            1.0,
            0.0,
            0.0
        );


    float3 bitangent =
        float3(
            0.0,
            0.0,
            signY
        );


    float viewNormal =
        dot(
            viewDirWS,
            projectionNormal
        );


    float viewU =
        dot(
            viewDirWS,
            tangent
        );


    float viewV =
        dot(
            viewDirWS,
            bitangent
        );


    return ParallaxOcclusionMapping(
        uv,
        float2(viewU, viewV),
        viewNormal
    );
}


// ============================================================
// POM - Z projection
// ============================================================

float2 GetParallaxUV_Z(
    float2 uv,
    float3 viewDirWS,
    float3 geometryNormalWS)
{
    float signZ =
        geometryNormalWS.z >= 0.0
        ? 1.0
        : -1.0;


    // UV mapping:
    //
    // U = X * signZ
    // V = Y
    //
    // Therefore:
    // Tangent   = X * signZ
    // Bitangent = -Y
    // Normal    = Z * signZ
    //
    // T x B = N
    //

    float3 projectionNormal =
        float3(
            0.0,
            0.0,
            signZ
        );


    float3 tangent =
        float3(
            signZ,
            0.0,
            0.0
        );


    float3 bitangent =
        float3(
            0.0,
            -1.0,
            0.0
        );


    float viewNormal =
        dot(
            viewDirWS,
            projectionNormal
        );


    float viewU =
        dot(
            viewDirWS,
            tangent
        );


    float viewV =
        dot(
            viewDirWS,
            bitangent
        );


    return ParallaxOcclusionMapping(
        uv,
        float2(viewU, viewV),
        viewNormal
    );
}


// ============================================================
// Color
// ============================================================

float4 SampleTriplanarColor(
    float2 uvX,
    float2 uvY,
    float2 uvZ,
    float3 weights)
{
    float4 colorX =
        SAMPLE_TEXTURE2D(
            _BaseMap,
            sampler_BaseMap,
            uvX
        );

    float4 colorY =
        SAMPLE_TEXTURE2D(
            _BaseMap,
            sampler_BaseMap,
            uvY
        );

    float4 colorZ =
        SAMPLE_TEXTURE2D(
            _BaseMap,
            sampler_BaseMap,
            uvZ
        );


    return
        colorX * weights.x +
        colorY * weights.y +
        colorZ * weights.z;
}


// ============================================================
// Metallic
// ============================================================

float SampleTriplanarMetallic(
    float2 uvX,
    float2 uvY,
    float2 uvZ,
    float3 weights)
{
    float metallicX =
        SAMPLE_TEXTURE2D(
            _MetallicGlossMap,
            sampler_MetallicGlossMap,
            uvX
        ).r;


    float metallicY =
        SAMPLE_TEXTURE2D(
            _MetallicGlossMap,
            sampler_MetallicGlossMap,
            uvY
        ).r;


    float metallicZ =
        SAMPLE_TEXTURE2D(
            _MetallicGlossMap,
            sampler_MetallicGlossMap,
            uvZ
        ).r;


    float metallic =
        metallicX * weights.x +
        metallicY * weights.y +
        metallicZ * weights.z;


    return saturate(
        metallic * _Metallic
    );
}


// ============================================================
// AO
// ============================================================

float SampleTriplanarAO(
    float2 uvX,
    float2 uvY,
    float2 uvZ,
    float3 weights)
{
    float aoX =
        SAMPLE_TEXTURE2D(
            _OcclusionMap,
            sampler_OcclusionMap,
            uvX
        ).r;


    float aoY =
        SAMPLE_TEXTURE2D(
            _OcclusionMap,
            sampler_OcclusionMap,
            uvY
        ).r;


    float aoZ =
        SAMPLE_TEXTURE2D(
            _OcclusionMap,
            sampler_OcclusionMap,
            uvZ
        ).r;


    float ao =
        aoX * weights.x +
        aoY * weights.y +
        aoZ * weights.z;


    return lerp(
        1.0,
        ao,
        _OcclusionStrength
    );
}


// ============================================================
// Normal map
// ============================================================

float3 SampleTriplanarNormalMap(float2 uv)
{
    // Use URP's normal decoder so the normal texture is treated
    // exactly like a regular URP normal map.
    float3 normalTS =
        UnpackNormalScale(
            SAMPLE_TEXTURE2D(
                _BumpMap,
                sampler_BumpMap,
                uv
            ),
            _BumpScale
        );


    return normalize(normalTS);
}


// ============================================================
// Normal - X
// ============================================================

float3 SampleNormalX(
    float2 uv,
    float3 geometryNormalWS)
{
    float3 normalTS =
        SampleTriplanarNormalMap(uv);


    float signX =
        geometryNormalWS.x >= 0.0
        ? 1.0
        : -1.0;


    // Must match GetTriplanarUV:
    //
    // U = Z * signX
    // V = Y
    //
    // Right-handed basis:
    // T =  Z * signX
    // B = -Y
    // N =  X * signX
    //

    float3 tangent =
        float3(
            0.0,
            0.0,
            signX
        );


    float3 bitangent =
        float3(
            0.0,
            -1.0,
            0.0
        );


    float3 normal =
        float3(
            signX,
            0.0,
            0.0
        );


    return normalize(
        tangent * normalTS.x +
        bitangent * normalTS.y +
        normal * normalTS.z
    );
}


// ============================================================
// Normal - Y
// ============================================================

float3 SampleNormalY(
    float2 uv,
    float3 geometryNormalWS)
{
    float3 normalTS =
        SampleTriplanarNormalMap(uv);


    float signY =
        geometryNormalWS.y >= 0.0
        ? 1.0
        : -1.0;


    // Must match GetTriplanarUV:
    //
    // U = X
    // V = Z * signY
    //
    // Right-handed basis:
    // T = X
    // B = Z * signY
    // N = Y * signY
    //

    float3 tangent =
        float3(
            1.0,
            0.0,
            0.0
        );


    float3 bitangent =
        float3(
            0.0,
            0.0,
            signY
        );


    float3 normal =
        float3(
            0.0,
            signY,
            0.0
        );


    return normalize(
        tangent * normalTS.x +
        bitangent * normalTS.y +
        normal * normalTS.z
    );
}


// ============================================================
// Normal - Z
// ============================================================

float3 SampleNormalZ(
    float2 uv,
    float3 geometryNormalWS)
{
    float3 normalTS =
        SampleTriplanarNormalMap(uv);


    float signZ =
        geometryNormalWS.z >= 0.0
        ? 1.0
        : -1.0;


    // Must match GetTriplanarUV:
    //
    // U = X * signZ
    // V = Y
    //
    // Right-handed basis:
    // T = X * signZ
    // B = -Y
    // N = Z * signZ
    //

    float3 tangent =
        float3(
            signZ,
            0.0,
            0.0
        );


    float3 bitangent =
        float3(
            0.0,
            -1.0,
            0.0
        );


    float3 normal =
        float3(
            0.0,
            0.0,
            signZ
        );


    return normalize(
        tangent * normalTS.x +
        bitangent * normalTS.y +
        normal * normalTS.z
    );
}


// ============================================================
// Triplanar normal
// ============================================================

float3 SampleTriplanarNormal(
    float2 uvX,
    float2 uvY,
    float2 uvZ,
    float3 geometryNormalWS,
    float3 weights)
{
    float3 normalX =
        SampleNormalX(
            uvX,
            geometryNormalWS
        );


    float3 normalY =
        SampleNormalY(
            uvY,
            geometryNormalWS
        );


    float3 normalZ =
        SampleNormalZ(
            uvZ,
            geometryNormalWS
        );


    float3 blendedNormal =
        normalX * weights.x +
        normalY * weights.y +
        normalZ * weights.z;


    return normalize(blendedNormal);
}


// ============================================================
// Forward vertex
// ============================================================

struct TriplanarAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct TriplanarVaryings
{
    float4 positionCS : SV_POSITION;

    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


    TriplanarVaryings TriplanarLitVertex(
    TriplanarAttributes input)
    {
        TriplanarVaryings output;

        UNITY_SETUP_INSTANCE_ID(input);

        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


        VertexPositionInputs positionInputs =
        GetVertexPositionInputs(
            input.positionOS.xyz
        );


        VertexNormalInputs normalInputs =
        GetVertexNormalInputs(
            input.normalOS
        );


        output.positionCS =
        positionInputs.positionCS;


        output.positionWS =
        positionInputs.positionWS;


        output.normalWS =
        normalize(
            normalInputs.normalWS
        );


        return output;
    }


// ============================================================
// Forward fragment
// ============================================================

    half4 TriplanarLitFragment(
    TriplanarVaryings input)
    : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(input);


        float3 positionWS =
        input.positionWS;


        float3 geometryNormalWS =
        normalize(
            input.normalWS
        );


        float3 viewDirWS =
        GetWorldSpaceNormalizeViewDir(
            positionWS
        );


        float2 uvX;
        float2 uvY;
        float2 uvZ;


        GetTriplanarUV(
        positionWS,
        geometryNormalWS,
        uvX,
        uvY,
        uvZ
    );


    // --------------------------------------------------------
    // Height / POM
    // --------------------------------------------------------

        float2 parallaxUVX =
        GetParallaxUV_X(
            uvX,
            viewDirWS,
            geometryNormalWS
        );


        float2 parallaxUVY =
        GetParallaxUV_Y(
            uvY,
            viewDirWS,
            geometryNormalWS
        );


        float2 parallaxUVZ =
        GetParallaxUV_Z(
            uvZ,
            viewDirWS,
            geometryNormalWS
        );


    // --------------------------------------------------------
    // Triplanar weights
    // --------------------------------------------------------

        float3 weights =
        GetTriplanarWeights(
            geometryNormalWS
        );


    // --------------------------------------------------------
    // Material
    // --------------------------------------------------------

        float4 baseColor =
        SampleTriplanarColor(
            parallaxUVX,
            parallaxUVY,
            parallaxUVZ,
            weights
        );


        baseColor *= _BaseColor;


        float metallic =
        SampleTriplanarMetallic(
            parallaxUVX,
            parallaxUVY,
            parallaxUVZ,
            weights
        );


        float ao =
        SampleTriplanarAO(
            parallaxUVX,
            parallaxUVY,
            parallaxUVZ,
            weights
        );


        float3 normalWS =
        SampleTriplanarNormal(
            parallaxUVX,
            parallaxUVY,
            parallaxUVZ,
            geometryNormalWS,
            weights
        );


    // --------------------------------------------------------
    // InputData
    // --------------------------------------------------------

        InputData inputData =
        (InputData) 0;


        inputData.positionWS =
        positionWS;


        inputData.normalWS =
        normalWS;


        inputData.viewDirectionWS =
        viewDirWS;


        inputData.shadowCoord =
        TransformWorldToShadowCoord(
            positionWS
        );


        inputData.normalizedScreenSpaceUV =
        GetNormalizedScreenSpaceUV(
            input.positionCS
        );


        inputData.fogCoord =
        ComputeFogFactor(
            input.positionCS.z
        );


        inputData.vertexLighting =
        VertexLighting(
            positionWS,
            normalWS
        );


        inputData.bakedGI =
        SampleSH(
            normalWS
        );


    // --------------------------------------------------------
    // SurfaceData
    // --------------------------------------------------------

        SurfaceData surfaceData =
        (SurfaceData) 0;


        surfaceData.albedo =
        baseColor.rgb;


        surfaceData.metallic =
        metallic;


        surfaceData.specular =
        float3(
            0.0,
            0.0,
            0.0
        );


        surfaceData.smoothness =
        _Smoothness;


        surfaceData.normalTS =
        float3(
            0.0,
            0.0,
            1.0
        );


        surfaceData.occlusion =
        ao;


        surfaceData.emission =
        float3(
            0.0,
            0.0,
            0.0
        );


        surfaceData.alpha =
        baseColor.a;


        surfaceData.clearCoatMask =
        0.0;


        surfaceData.clearCoatSmoothness =
        0.0;


    // --------------------------------------------------------
    // URP PBR
    // --------------------------------------------------------

        half4 color =
        UniversalFragmentPBR(
            inputData,
            surfaceData
        );


    // Height Color is deliberately applied AFTER PBR lighting.
        float heightColorMask =
        GetTriplanarHeightColorMask(
            parallaxUVX,
            parallaxUVY,
            parallaxUVZ,
            weights
        );


        color.rgb =
        lerp(
            color.rgb,
            color.rgb * _HeightColor.rgb,
            heightColorMask
        );


        color.rgb =
        MixFog(
            color.rgb,
            inputData.fogCoord
        );


        return color;
    }


// ============================================================
// DepthNormals vertex
// ============================================================

    struct DepthNormalsAttributes
    {
        float4 positionOS : POSITION;
        float3 normalOS : NORMAL;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    };


    struct DepthNormalsVaryings
    {
        float4 positionCS : SV_POSITION;

        float3 positionWS : TEXCOORD0;
        float3 normalWS : TEXCOORD1;

        UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


        DepthNormalsVaryings TriplanarDepthNormalsVertex(
    DepthNormalsAttributes input)
        {
            DepthNormalsVaryings output;

            UNITY_SETUP_INSTANCE_ID(input);

            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);


            VertexPositionInputs positionInputs =
        GetVertexPositionInputs(
            input.positionOS.xyz
        );


            VertexNormalInputs normalInputs =
        GetVertexNormalInputs(
            input.normalOS
        );


            output.positionCS =
        positionInputs.positionCS;


            output.positionWS =
        positionInputs.positionWS;


            output.normalWS =
        normalize(
            normalInputs.normalWS
        );


            return output;
        }


// ============================================================
// DepthNormals fragment
// ============================================================

        half4 TriplanarDepthNormalsFragment(
    DepthNormalsVaryings input)
    : SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);


            float3 positionWS =
        input.positionWS;


            float3 geometryNormalWS =
        normalize(
            input.normalWS
        );


            float3 viewDirWS =
        GetWorldSpaceNormalizeViewDir(
            positionWS
        );


            float2 uvX;
            float2 uvY;
            float2 uvZ;


            GetTriplanarUV(
        positionWS,
        geometryNormalWS,
        uvX,
        uvY,
        uvZ
    );


            float2 parallaxUVX =
        GetParallaxUV_X(
            uvX,
            viewDirWS,
            geometryNormalWS
        );


            float2 parallaxUVY =
        GetParallaxUV_Y(
            uvY,
            viewDirWS,
            geometryNormalWS
        );


            float2 parallaxUVZ =
        GetParallaxUV_Z(
            uvZ,
            viewDirWS,
            geometryNormalWS
        );


            float3 weights =
        GetTriplanarWeights(
            geometryNormalWS
        );


            float3 normalWS =
        SampleTriplanarNormal(
            parallaxUVX,
            parallaxUVY,
            parallaxUVZ,
            geometryNormalWS,
            weights
        );


            return half4(
        normalWS * 0.5 + 0.5,
        1.0
    );
        }


#endif