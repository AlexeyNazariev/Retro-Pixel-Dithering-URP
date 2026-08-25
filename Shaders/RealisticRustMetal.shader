Shader "Custom/RealisticRustMetal"
{
    Properties
    {
        [Header(Base Metal)]
        _BaseColor ("Metal Color Tint", Color) = (0.75, 0.77, 0.8, 1.0)
        _BaseMap ("Base Metal Texture", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0, 2)) = 1.0
        _Metallic ("Metalness", Range(0, 1)) = 0.95
        _Smoothness ("Smoothness", Range(0, 1)) = 0.75

        [Header(Rust Details)]
        _RustColor ("Rust Color Tint", Color) = (0.45, 0.18, 0.08, 1.0)
        _RustTex ("Rust Texture Map", 2D) = "white" {}
        _RustNormalMap ("Rust Normal Map", 2D) = "bump" {}
        _RustTexTiling ("Rust Tiling", Float) = 2.0
        _RustAmount ("Rust Amount", Range(0, 1)) = 0.4
        _RustScale ("Rust Noise Scale", Range(0.5, 20)) = 4.0
        _RustContrast ("Rust Contrast", Range(1, 10)) = 3.0
        _RustBumpStrength ("Rust Bump Strength", Range(0, 2)) = 0.8
        _RustSmoothness ("Rust Smoothness", Range(0, 1)) = 0.15

        [Header(Scratches)]
        _ScratchStrength ("Scratch Intensity", Range(0, 1)) = 0.4
        _ScratchScale ("Scratch Scale", Range(5, 50)) = 25.0

        [Header(Retro Shadow Modulation)]
        _ShadowDarkness ("Shadow Darkness", Range(0, 1)) = 0.6
        _ShadowContrast ("Shadow Contrast", Range(0.5, 4.0)) = 1.5
        _UnlitSideDarkness ("Ambient Darkness", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline" 
            "Queue"="Geometry"
        }
        
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            // URP Lighting & Shadow keywords (Universal Forward, Forward+, Additional Lights / Point Lights)
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma multi_compile _ _EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _CLUSTERED_RENDERING
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma shader_feature_local _NORMALMAP

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 positionOS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float4 tangentWS    : TEXCOORD3;
                float2 uv           : TEXCOORD4;
                float3 vertexSH     : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            TEXTURE2D(_RustTex);
            SAMPLER(sampler_RustTex);

            TEXTURE2D(_RustNormalMap);
            SAMPLER(sampler_RustNormalMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _RustColor;
                float _BumpScale;
                float _Metallic;
                float _Smoothness;
                float _RustAmount;
                float _RustTexTiling;
                float _RustScale;
                float _RustContrast;
                float _RustBumpStrength;
                float _RustSmoothness;
                float _ScratchStrength;
                float _ScratchScale;
                float _ShadowDarkness;
                float _ShadowContrast;
                float _UnlitSideDarkness;
            CBUFFER_END

            float3 hash33(float3 p)
            {
                p = frac(p * float3(443.897, 441.423, 437.195));
                p += dot(p, p.yxz + 19.19);
                return frac((p.xxy + p.yxx) * p.zyx);
            }

            float ValueNoise3D(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);

                float n000 = dot(hash33(i + float3(0,0,0)) - 0.5, f - float3(0,0,0));
                float n100 = dot(hash33(i + float3(1,0,0)) - 0.5, f - float3(1,0,0));
                float n010 = dot(hash33(i + float3(0,1,0)) - 0.5, f - float3(0,1,0));
                float n110 = dot(hash33(i + float3(1,1,0)) - 0.5, f - float3(1,1,0));
                float n001 = dot(hash33(i + float3(0,0,1)) - 0.5, f - float3(0,0,1));
                float n101 = dot(hash33(i + float3(1,0,1)) - 0.5, f - float3(1,0,1));
                float n011 = dot(hash33(i + float3(0,1,1)) - 0.5, f - float3(0,1,1));
                float n111 = dot(hash33(i + float3(1,1,1)) - 0.5, f - float3(1,1,1));

                float lx0 = lerp(n000, n100, f.x);
                float lx1 = lerp(n001, n101, f.x);
                float ly0 = lerp(n010, n110, f.x);
                float ly1 = lerp(n011, n111, f.x);

                return lerp(lerp(lx0, ly0, f.y), lerp(lx1, ly1, f.y), f.z) + 0.5;
            }

            float FBM3D(float3 p, int octaves)
            {
                float val = 0.0;
                float amp = 0.5;
                float freq = 1.0;
                for (int i = 0; i < octaves; i++)
                {
                    val += amp * ValueNoise3D(p * freq);
                    freq *= 2.03;
                    amp *= 0.5;
                }
                return val;
            }

            float ScratchPattern(float3 posOS, float scale)
            {
                float3 p = posOS * scale;
                float n1 = ValueNoise3D(float3(p.x * 15.0, p.y * 1.5, p.z * 15.0));
                float n2 = ValueNoise3D(float3(p.x * 1.5, p.y * 15.0, p.z * 1.5));
                return saturate(pow(abs(n1 - n2), 0.6) * 1.5);
            }

            Varyings Vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = posInputs.positionCS;
                output.positionWS = posInputs.positionWS;
                output.positionOS = input.positionOS.xyz;
                output.normalWS = normInputs.normalWS;
                output.tangentWS = float4(normInputs.tangentWS, input.tangentOS.w);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.vertexSH = SampleSHVertex(normInputs.normalWS);

                return output;
            }

            float4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 normalWS = normalize(input.normalWS);

                float3 objNoisePos = input.positionOS * _RustScale;
                float noiseRust = FBM3D(objNoisePos, 4);

                float rawRustMask = noiseRust + (_RustAmount - 0.5) * 1.5;
                float rustMask = saturate(pow(max(0.0, rawRustMask), _RustContrast));

                float scratch = ScratchPattern(input.positionOS, _ScratchScale) * _ScratchStrength;

                float4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float3 metalAlbedo = texColor.rgb * _BaseColor.rgb;
                metalAlbedo = lerp(metalAlbedo, metalAlbedo * 0.7, scratch * (1.0 - rustMask));

                float2 rustUV = input.uv * _RustTexTiling;
                float4 rustTexColor = SAMPLE_TEXTURE2D(_RustTex, sampler_RustTex, rustUV);

                float rustToneNoise = ValueNoise3D(objNoisePos * 3.0);
                float3 rustColorBase = _RustColor.rgb * rustTexColor.rgb;
                float3 rustAlbedo = lerp(rustColorBase, rustColorBase * float3(1.3, 0.8, 0.4), rustToneNoise);

                float3 finalAlbedo = lerp(metalAlbedo, rustAlbedo, rustMask);

                float finalMetallic = lerp(_Metallic, 0.0, rustMask);
                float metalSmoothness = saturate(_Smoothness - scratch * 0.3);
                float finalSmoothness = lerp(metalSmoothness, _RustSmoothness, rustMask);

                float3 normalTS = float3(0, 0, 1);
                #if defined(_NORMALMAP)
                    normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv), _BumpScale);
                #endif

                float3 rustNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_RustNormalMap, sampler_RustNormalMap, rustUV), 1.0);
                
                float3 rustBumpNoise = float3(
                    ValueNoise3D(objNoisePos * 8.0) - 0.5,
                    ValueNoise3D(objNoisePos * 8.0 + 10.0) - 0.5,
                    1.0
                ) * _RustBumpStrength;
                
                rustNormalTS += rustBumpNoise;
                normalTS = normalize(lerp(normalTS, rustNormalTS, rustMask));

                InputData inputData;
                ZERO_INITIALIZE(InputData, inputData);
                inputData.positionWS = input.positionWS;

                float3 sgn = input.tangentWS.w > 0.0 ? 1.0 : -1.0;
                float3 bitangent = sgn * cross(normalWS, input.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent, normalWS);
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                inputData.normalWS = normalize(inputData.normalWS);

                inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                
                #if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
                    inputData.shadowCoord = ComputeScreenPos(input.positionCS);
                #else
                    inputData.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                #endif

                inputData.bakedGI = SAMPLE_GI(input.uv, input.vertexSH, inputData.normalWS) * (1.0 - _UnlitSideDarkness);
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = float4(1, 1, 1, 1);

                SurfaceData surfaceData;
                ZERO_INITIALIZE(SurfaceData, surfaceData);
                surfaceData.albedo = finalAlbedo;
                surfaceData.metallic = finalMetallic;
                surfaceData.smoothness = finalSmoothness;
                surfaceData.normalTS = normalTS;
                surfaceData.occlusion = lerp(1.0 - _ShadowDarkness * 0.5, 0.2, rustMask);
                surfaceData.alpha = 1.0;

                half4 finalColor = UniversalFragmentPBR(inputData, surfaceData);

                #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
                    finalColor.rgb = MixFog(finalColor.rgb, inputData.positionWS);
                #endif

                return finalColor;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            float3 _LightDirection;

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                return output;
            }

            half4 ShadowPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.positionCS = TransformWorldToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return input.positionCS.z;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings DepthNormalsVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = posInputs.positionCS;
                output.normalWS = normInputs.normalWS;
                return output;
            }

            half4 DepthNormalsFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                float3 normalWS = normalize(input.normalWS);
                return half4(NormalizeNormalPerPixel(normalWS), 0.0);
            }
            ENDHLSL
        }
    }
    FallBack "Universal Render Pipeline/Lit"
}
