using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;

namespace SpaceExtra
{
    /// <summary>
    /// URP Scriptable Renderer Feature utilizing RenderGraph API (Unity 6+) 
    /// for resolution-independent retro pixelation and dithering.
    /// </summary>
    public class RetroPixelRenderFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
            public Shader shader;

            [Header("Resolution & Pixelation")]
            [Tooltip("Enable fixed vertical resolution target (e.g. 240p, 360p, 480p)")]
            public bool useFixedResolution = true;

            [Range(120f, 1080f)]
            [Tooltip("Target vertical resolution lines")]
            public float targetVerticalResolution = 360f;

            [Tooltip("Reference screen height for relative scaling")]
            public float referenceHeight = 1080f;

            [Range(1f, 16f)]
            [Tooltip("Relative pixel size scaling factor")]
            public float pixelSize = 4f;

            [Header("Color & Dithering")]
            [Range(2f, 32f)] public float colorDepth = 8f;
            [Range(0f, 1f)] public float ditherStrength = 0.25f;
            [Range(2f, 64f)] public float paletteSteps = 16f;
            [Range(0.5f, 2.0f)] public float colorSaturation = 1.1f;
        }

        public Settings settings = new Settings();

        private RetroPixelPass retroPass;
        private Material material;

        public override void Create()
        {
            if (settings.shader == null)
            {
                settings.shader = Shader.Find("Retro/RetroPixelDither");
            }

            if (settings.shader != null)
            {
                material = CoreUtils.CreateEngineMaterial(settings.shader);
            }

            retroPass = new RetroPixelPass(material, settings);
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (material == null || !renderingData.cameraData.postProcessEnabled)
                return;

            renderer.EnqueuePass(retroPass);
        }

        protected override void Dispose(bool disposing)
        {
            CoreUtils.Destroy(material);
        }

        private class RetroPixelPass : ScriptableRenderPass
        {
            private Material mat;
            private Settings settings;

            private static readonly int UseFixedResolutionId = Shader.PropertyToID("_UseFixedResolution");
            private static readonly int TargetVerticalResolutionId = Shader.PropertyToID("_TargetVerticalResolution");
            private static readonly int ReferenceHeightId = Shader.PropertyToID("_ReferenceHeight");
            private static readonly int PixelSizeId = Shader.PropertyToID("_PixelSize");
            private static readonly int ColorDepthId = Shader.PropertyToID("_ColorDepth");
            private static readonly int DitherStrengthId = Shader.PropertyToID("_DitherStrength");
            private static readonly int PalettePosterizeId = Shader.PropertyToID("_PalettePosterize");
            private static readonly int ColorSaturationId = Shader.PropertyToID("_ColorSaturation");

            public RetroPixelPass(Material mat, Settings settings)
            {
                this.mat = mat;
                this.settings = settings;
                this.renderPassEvent = settings.renderPassEvent;
            }

            private class PassData
            {
                public Material material;
                public TextureHandle source;
            }

            public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
            {
                UniversalResourceData resourceData = frameData.Get<UniversalResourceData>();
                UniversalCameraData cameraData = frameData.Get<UniversalCameraData>();

                if (mat == null || !cameraData.postProcessEnabled)
                    return;

                mat.SetFloat(UseFixedResolutionId, settings.useFixedResolution ? 1f : 0f);
                mat.SetFloat(TargetVerticalResolutionId, settings.targetVerticalResolution);
                mat.SetFloat(ReferenceHeightId, settings.referenceHeight);
                mat.SetFloat(PixelSizeId, settings.pixelSize);
                mat.SetFloat(ColorDepthId, settings.colorDepth);
                mat.SetFloat(DitherStrengthId, settings.ditherStrength);
                mat.SetFloat(PalettePosterizeId, settings.paletteSteps);
                mat.SetFloat(ColorSaturationId, settings.colorSaturation);

                TextureHandle src = resourceData.activeColorTexture;
                if (!src.IsValid()) return;

                TextureDesc desc = renderGraph.GetTextureDesc(src);
                desc.name = "_RetroPixelTemp";
                desc.clearBuffer = false;

                TextureHandle destination = renderGraph.CreateTexture(desc);

                using (var builder = renderGraph.AddRasterRenderPass<PassData>("Retro Pixel Dither Pass", out var passData))
                {
                    passData.material = mat;
                    passData.source = src;

                    builder.UseTexture(src, AccessFlags.Read);
                    builder.SetRenderAttachment(destination, 0, AccessFlags.Write);

                    builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
                    {
                        Blitter.BlitTexture(context.cmd, data.source, new Vector4(1, 1, 0, 0), data.material, 0);
                    });
                }

                using (var builder = renderGraph.AddRasterRenderPass<PassData>("Retro Pixel Copy Back", out var passData))
                {
                    passData.source = destination;

                    builder.UseTexture(destination, AccessFlags.Read);
                    builder.SetRenderAttachment(src, 0, AccessFlags.Write);

                    builder.SetRenderFunc((PassData data, RasterGraphContext context) =>
                    {
                        Blitter.BlitTexture(context.cmd, data.source, new Vector4(1, 1, 0, 0), 0, false);
                    });
                }
            }
        }
    }
}
