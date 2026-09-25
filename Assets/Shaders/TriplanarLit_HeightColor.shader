Shader "Custom/TriplanarLit_HeightColor"
{
    Properties
    {
        [NoScaleOffset][MainTexture]
        _BaseMap("Color Map", 2D) = "white" {}

        [MainColor]
        _BaseColor("Color", Color) = (1,1,1,1)

        [NoScaleOffset]
        _BumpMap("Normal Map", 2D) = "bump" {}

        _BumpScale("Normal Strength", Range(0,2)) = 1.0

        [NoScaleOffset]
        _MetallicGlossMap("Metallic Map", 2D) = "black" {}

        _Metallic("Metallic", Range(0,1)) = 0.0

        [NoScaleOffset]
        _HeightMap("Height Map", 2D) = "gray" {}

        _HeightStrength("Height Strength", Range(0,0.1)) = 0.02
        _HeightSteps("Height Steps", Range(2,32)) = 12

        _HeightColor("Height Color", Color) = (1,0,0,1)
        _HeightColorStrength("Height Color Strength", Range(0,1)) = 0.0
        _HeightColorThreshold("Height Color Threshold", Range(0,1)) = 0.5
        _HeightColorSmoothness("Height Color Smoothness", Range(0.001,0.5)) = 0.08

        [NoScaleOffset]
        _OcclusionMap("Ambient Occlusion Map", 2D) = "white" {}

        _OcclusionStrength("AO Strength", Range(0,1)) = 1.0

        _Smoothness("Smoothness", Range(0,1)) = 0.5

        _TriplanarTiling("Tiling", Vector) = (1,1,0,0)
        _TriplanarOffset("Offset", Vector) = (0,0,0,0)

        _TriplanarBlendSharpness("Blend Sharpness", Range(1,32)) = 4.0

        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull("Cull", Float) = 2
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
        }

        Cull [_Cull]

        Pass
        {
            Name "ForwardLit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex TriplanarLitVertex
            #pragma fragment TriplanarLitFragment

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_SCREEN

            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            #pragma multi_compile _ _FORWARD_PLUS

            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma multi_compile_fog

            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma multi_compile_instancing

            #pragma multi_compile_fragment _ _LIGHT_LAYERS

            #include "TriplanarLit_HeightColor.hlsl"

            ENDHLSL
        }


        Pass
        {
            Name "ShadowCaster"

            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            ENDHLSL
        }


        Pass
        {
            Name "DepthOnly"

            Tags
            {
                "LightMode" = "DepthOnly"
            }

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"

            ENDHLSL
        }


        Pass
        {
            Name "DepthNormals"

            Tags
            {
                "LightMode" = "DepthNormals"
            }

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex TriplanarDepthNormalsVertex
            #pragma fragment TriplanarDepthNormalsFragment

            #pragma multi_compile_instancing

            #include "TriplanarLit_HeightColor.hlsl"

            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}