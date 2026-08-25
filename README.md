# Retro Pixel Dither & PBR Toolkit for Unity URP

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Unity](https://img.shields.io/badge/Unity-2022.3%20%7C%20Unity%206-blue.svg)](https://unity.com/)
[![RenderPipeline](https://img.shields.io/badge/URP-14.0%2B%20%2F%2017.0%2B-green.svg)](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@latest)
[![RenderGraph Ready](https://img.shields.io/badge/API-RenderGraph%20Native-orange.svg)](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@latest)

A production-ready graphics package for **Unity Universal Render Pipeline (URP)** combining authentic 90s retro visual processing (Bayer ordered dithering, resolution-locked pixelation, color depth quantization) with a procedural 3D object-space rust and scratched metal PBR surface shader.

Built for boomer shooters, retro sci-fi, survival horror, and isometric RTS/RPG aesthetics (inspired by the visual style of *Diablo I/II*, *StarCraft*, *Fallout 1/2*, and early 3D PC titles).

---

## Features

### 1. Screen-Space Retro Pixelation & Dithering (`RetroPixelDither.shader`)
* **Aspect-Correct Resolution Snapping:** Locks target vertical lines (e.g. `240p`, `360p`, `480p`) dynamically across any monitor aspect ratio (16:9, 16:10, 21:9) with square retro pixels.
* **4x4 Bayer Ordered Dithering:** Bitwise GPU-evaluated Bayer threshold matrix `(p.y & 3, p.x & 3)` eliminates color banding without temporal frame noise.
* **Quantization & Bit-Depth:** Configurable color depth per channel (2-bit to 8-bit) and palette posterization steps.
* **Luminance Saturation Boost:** Integrated saturation grading that preserves perceptual luminance before quantization.

### 2. Procedural Rust & Scratched Metal PBR Shader (`RealisticRustMetal.shader`)
* **3D Object-Space Procedural Noise:** Generates organic rust formations via 4-octave 3D Fractional Brownian Motion (FBM) and Value Noise—completely independent of UV unwrapping, avoiding texture stretching and visible seams.
* **Multi-Layer Surface Composite:** Physically blends between smooth metallic base, micro-scratches/scuffs, and dielectric porous oxidation.
* **Crust Bump Micro-Detailing:** Normal map blending with procedural high-frequency noise for raised, flaky rust crusts.
* **Retro Dark Shadow Modulation:** Ambient occlusion and shadow contrast curves tuned for gritty, high-contrast atmospheric rendering.
* **Full Lighting Feature Support:** Native URP Forward+ clustering, additional point/spot shadow maps, `DepthNormals` pass (SSAO-ready), Reflection Probes, Fog mixing, and GPU Instancing.

### 3. Unity 6 RenderGraph Feature (`RetroPixelRenderFeature.cs`)
* Fully implemented using the **Unity 6 RenderGraph API** (`RecordRenderGraph` + `AddRasterRenderPass` + `Blitter`).
* Clean dual-pass raster blit workflow ensuring zero frame buffer feedback loops and proper integration with URP post-processing stacks.

### 4. Gameplay Utility Scripts
* **`FanRotator.cs`:** Multi-axis prop rotation with local/world space support, customizable speed, and smooth acceleration damping.
* **`RTSCameraController.cs`:** Fixed-elevation tactical camera controller using the Unity New Input System, featuring smooth interpolation, keyboard panning, and screen edge scrolling.

---

## File Structure

```
Unity_Retro_Shaders/
├── Shaders/
│   ├── RetroPixelDither.shader        # Fullscreen Bayer dithering & pixelation HLSL shader
│   └── RealisticRustMetal.shader      # Procedural PBR rust & scratched metal HLSL shader
├── Scripts/
│   ├── RetroPixelRenderFeature.cs     # Unity 6 URP ScriptableRendererFeature (RenderGraph)
│   ├── FanRotator.cs                  # Prop rotation utility component
│   └── RTSCameraController.cs         # Tactical / RTS camera controller (New Input System)
├── LICENSE                            # MIT License
└── README.md                          # Documentation
```

---

## Compatibility

| Environment | Supported Versions | Notes |
| :--- | :--- | :--- |
| **Unity** | `2022.3 LTS`, `2023.x`, `Unity 6 (6000.x)` | Tested on Unity 6 and 2022.3 LTS |
| **Render Pipeline** | URP `14.0+` to `17.0+` | RenderGraph API active on Unity 6 |
| **Rendering Paths** | Forward, Forward+, Deferred | Full light clustering & shadow passes |
| **Platforms** | Windows (DX11/DX12/Vulkan), macOS/iOS (Metal), Linux, Android (Vulkan/GLES3), WebGL | Register-based procedural noise (no texture fetch bottlenecks) |

---

## Installation & Setup

### Method A: URP Scriptable Renderer Feature (Unity 6 RenderGraph)

1. Copy the `Shaders/` and `Scripts/` folders into your Unity project's `Assets/` directory.
2. In your Project window, select your active **Universal Renderer Data** asset (e.g., `UniversalRenderer.asset` or `PC_Renderer.asset`).
3. In the Inspector, click **Add Renderer Feature** and choose **Retro Pixel Render Feature**.
4. Configure parameters:
   * **Use Fixed Resolution:** `True`
   * **Target Vertical Lines:** `360` (or `240` for classic PS1/DOS look)
   * **Dither Strength:** `0.25`
   * **Color Depth:** `8`
   * **Palette Steps:** `16`
5. Ensure **Post Processing** is enabled on your Main Camera.

---

### Method B: Full Screen Pass Feature (Unity 2022.3 LTS / Fallback)

1. Create a new Material in Unity (`Assets` -> `Create` -> `Material`) and name it `Mat_RetroPixelDither`.
2. Set its shader to `Retro/RetroPixelDither`.
3. Select your **Universal Renderer Data** asset.
4. Click **Add Renderer Feature** -> **Full Screen Pass Renderer Feature**.
5. Set **Pass Material** to your `Mat_RetroPixelDither` and set **Injection Point** to `After Rendering Post Processing`.

---

### Setting Up the Procedural Rust Metal Material

1. Create a new Material and select `Custom/RealisticRustMetal`.
2. Assign it to any 3D mesh (industrial props, pipes, machinery, structures).
3. Optional textures:
   * **Base Metal Texture / Normal Map:** For macro metal detailing.
   * **Rust Texture Map / Rust Normal Map:** For additional surface roughness variation.
4. The shader automatically handles procedural rust distribution and micro-scratches via object-space math even without assigned textures.

---

## Inspector Parameter Reference

### `RetroPixelDither.shader` / `RetroPixelRenderFeature`

| Property | Default | Description |
| :--- | :--- | :--- |
| `_UseFixedResolution` | `True` | When enabled, locks pixel grid to a fixed vertical line count. |
| `_TargetVerticalResolution` | `360` | Vertical line target (`240` = classic low-res CRT, `360` = retro balance, `480` = VGA/SD). |
| `_PixelSize` | `4` | Pixel scaling factor when fixed resolution is disabled. |
| `_ColorDepth` | `8` | Quantization divisor per RGB channel. Lower values introduce starker color steps. |
| `_DitherStrength` | `0.25` | Amplitude of the 4x4 Bayer matrix dither offset. |
| `_PalettePosterize` | `16` | Step count for discrete palette posterization. |
| `_ColorSaturation` | `1.1` | Pre-dither color saturation boost. |

### `RealisticRustMetal.shader`

| Property | Default | Description |
| :--- | :--- | :--- |
| `_BaseColor` | `(0.75, 0.77, 0.8, 1)` | Base metal tint color. |
| `_Metallic` | `0.95` | Metalness for unrusted surface areas (non-rusted = metallic, rusted = dielectric `0.0`). |
| `_Smoothness` | `0.75` | Base smoothness / glossiness of clean metal. |
| `_RustColor` | `(0.45, 0.18, 0.08, 1)` | Oxidation tint color. |
| `_RustAmount` | `0.4` | Global procedural rust coverage threshold (`0.0` = clean, `1.0` = heavy corrosion). |
| `_RustScale` | `4.0` | Spatial frequency of procedural 3D rust clusters. |
| `_RustContrast` | `3.0` | Edge sharpness of rust transition zones. |
| `_RustBumpStrength` | `0.8` | Procedural crust displacement intensity for rusted areas. |
| `_ScratchStrength` | `0.4` | Intensity of procedural surface scratches and scuffs. |
| `_ShadowDarkness` | `0.6` | Ambient / shadow depth boost for high-contrast retro lighting. |
| `_ShadowContrast` | `1.5` | Exponential falloff exponent for directional shadow attenuation. |

---

## Technical Notes

### Bayer 4x4 Dither Matrix
The shader implements a standard 4x4 threshold matrix normalized to `[0..1]`, centered at `-0.5`:

```hlsl
static const float4x4 Bayer4x4 = float4x4(
     0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
    12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
     3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
    15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

float GetBayerValue(float2 pixelCoord)
{
    uint2 p = (uint2)max(0.0, pixelCoord);
    return Bayer4x4[p.y & 3][p.x & 3] - 0.5;
}
```

### Tips for Best Retro Results
1. **Texture Filtering:** Set texture import settings to **Filter Mode: Point (no filter)** and disable **Generate Mip Maps** on diffuse textures for pixel-crisp surfaces.
2. **Anti-Aliasing:** Disable MSAA and Temporal Anti-Aliasing (TAA) on your camera to avoid blurring the dither pattern.
3. **Lighting Style:** Pair with low ambient light and stark directional or point lights to maximize the contrast of the Bayer dither gradients.

---

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and distribute it in personal and commercial projects.
