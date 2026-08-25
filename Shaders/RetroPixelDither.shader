Shader "Retro/RetroPixelDither"
{
    Properties
    {
        [Header(Resolution Settings)]
        [Toggle] _UseFixedResolution ("Use Fixed Vertical Lines", Float) = 1
        _TargetVerticalResolution ("Target Vertical Lines", Range(120, 1080)) = 360
        _ReferenceHeight ("Reference Monitor Height", Float) = 1080
        _PixelSize ("Pixel Size", Range(1, 16)) = 4

        [Header(Color and Dither)]
        _ColorDepth ("Color Depth per Channel", Range(2, 32)) = 8
        _DitherStrength ("Dither Strength", Range(0, 1)) = 0.25
        _PalettePosterize ("Palette Steps", Range(2, 64)) = 16
        _ColorSaturation ("Color Saturation", Range(0.5, 2.0)) = 1.1
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline"
        }
        
        LOD 100
        ZWrite Off
        Cull Off

        Pass
        {
            Name "RetroPixelDitherPass"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                uint vertexID : SV_VertexID;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D_X(_BlitTexture);
            SAMPLER(sampler_BlitTexture);

            CBUFFER_START(UnityPerMaterial)
                float _UseFixedResolution;
                float _TargetVerticalResolution;
                float _ReferenceHeight;
                float _PixelSize;
                float _ColorDepth;
                float _DitherStrength;
                float _PalettePosterize;
                float _ColorSaturation;
            CBUFFER_END

            static const float4x4 Bayer4x4 = float4x4(
                 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
                12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
                 3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
                15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
            );

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.uv = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            float GetBayerValue(float2 pixelCoord)
            {
                uint2 p = (uint2)max(0.0, pixelCoord);
                return Bayer4x4[p.y & 3][p.x & 3] - 0.5;
            }

            float3 AdjustSaturation(float3 color, float sat)
            {
                float luma = dot(color, float3(0.2126, 0.7152, 0.0722));
                return lerp(float3(luma, luma, luma), color, sat);
            }

            float4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 screenRes = _ScreenParams.xy;
                float aspect = screenRes.x / max(1.0, screenRes.y);
                
                float targetVerticalPixels;
                if (_UseFixedResolution > 0.5)
                {
                    targetVerticalPixels = max(32.0, _TargetVerticalResolution);
                }
                else
                {
                    float refHeight = max(100.0, _ReferenceHeight);
                    targetVerticalPixels = refHeight / max(1.0, _PixelSize);
                }

                float2 targetRes = float2(targetVerticalPixels * aspect, targetVerticalPixels);
                float2 pixelatedUV = (floor(input.uv * targetRes) + 0.5) / targetRes;

                float4 rawColor = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_BlitTexture, pixelatedUV);
                float3 color = rawColor.rgb;

                color = AdjustSaturation(color, _ColorSaturation);

                float2 retroPixelCoord = floor(input.uv * targetRes);
                float dither = GetBayerValue(retroPixelCoord) * _DitherStrength;

                float depthStep = max(1.0, _ColorDepth);
                color += dither / depthStep;

                color = clamp(color, 0.0, 1.0);
                float posterize = max(2.0, _PalettePosterize);
                color = floor(color * (posterize - 1.0) + 0.5) / (posterize - 1.0);

                return float4(color, rawColor.a);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
