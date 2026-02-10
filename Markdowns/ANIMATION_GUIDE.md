# Animation Features Guide
**Project:** MECH0020 - Numerical Analysis of Tsunami Vortices  
**Date:** January 27, 2026  
**Purpose:** Create high-quality vortex evolution animations with controllable speed and resolution

---

## Overview

The analysis framework now supports **three animation formats** with full control over playback speed and frame count:

| Format | Extension | Speed Control | Quality | File Size | Use Case |
|--------|-----------|---------------|---------|-----------|----------|
| **GIF** | `.gif` | Fixed delay | 256 colors | Small-Medium | Web/presentations, looping |
| **MP4** | `.mp4` | Adjustable FPS | High quality | Small | Video playback, publications |
| **AVI** | `.avi` | Adjustable FPS | Lossless option | Large | Archival, post-processing |

---

## Quick Start

### 1. Animation Mode (High-Resolution)
For detailed evolution visualization with many frames:

```matlab
% Configure animation mode
run_mode = "animation";

% Animation settings
settings.animation.format = 'mp4';           % 'gif', 'mp4', 'avi'
settings.animation.fps = 30;                 % Frames per second
settings.animation.quality = 90;             % Video quality (0-100)
settings.animation.num_frames = 100;         % High frame count!

% Run analysis
[T, meta] = run_animation_mode(Parameters, settings, run_mode);
```

**Output:**
- 100-frame animation showing smooth vortex evolution
- MP4 video at 30 FPS = 3.33 seconds duration
- Saved to `Figures/Finite Difference/Animations/`

---

### 2. Standard Modes (Evolution/Convergence/Sweep)
For quick animations alongside analysis:

```matlab
run_mode = "evolution";

% Set animation parameters in Parameters struct
Parameters.animation_format = 'mp4';
Parameters.animation_fps = 24;
Parameters.animation_quality = 85;
Parameters.snap_times = linspace(0, Parameters.Tfinal, 50);  % 50 frames

% Run analysis (animation created automatically)
[T, meta] = run_evolution_mode(Parameters, settings, run_mode);
```

---

## Format Comparison

### GIF Animation
**Advantages:**
- ✅ Auto-loops in browsers and presentations
- ✅ Small file size
- ✅ Universal compatibility (no codec needed)
- ✅ Easy to embed in markdown/web

**Disadvantages:**
- ❌ Limited to 256 colors (color banding possible)
- ❌ Fixed playback speed (no pause/scrub)
- ❌ Larger than MP4 for high frame counts

**Configuration:**
```matlab
Parameters.animation_format = 'gif';
Parameters.animation_fps = 10;  % Controls delay between frames
```

**Output Example:**
```
vorticity_evolution_Nx128_Ny128_nu0.0000_dt0.0100_Tfinal8.0_ic_stretched_gaussian_mode_solve_20260127_153045.gif
Size: ~2-5 MB (for 50 frames)
```

---

### MP4 Animation (Recommended)
**Advantages:**
- ✅ Excellent compression (smallest file size)
- ✅ Full color depth (no banding)
- ✅ Controllable playback speed
- ✅ Adjustable quality (tradeoff size vs clarity)
- ✅ Widely supported (all modern players)

**Disadvantages:**
- ❌ Requires codec (usually built-in)
- ❌ No auto-loop by default

**Configuration:**
```matlab
Parameters.animation_format = 'mp4';
Parameters.animation_fps = 30;       % Standard video framerate
Parameters.animation_quality = 90;   % 0-100 (higher = better quality, larger file)
```

**Codec Selection:**
```matlab
% Default (recommended)
Parameters.animation_codec = 'MPEG-4';

% Alternative (higher compression, may not be available on all systems)
Parameters.animation_codec = 'H.264';
```

**Output Example:**
```
vorticity_evolution_Nx256_Ny256_nu0.0001_dt0.0050_Tfinal8.0_ic_stretched_gaussian_mode_animation_20260127_153045.mp4
Size: ~500 KB - 3 MB (for 100 frames at quality 90)
Duration: 3.33 seconds at 30 FPS
```

---

### AVI Animation
**Advantages:**
- ✅ Lossless uncompressed option (archival quality)
- ✅ No codec issues (built-in to MATLAB)
- ✅ Frame-accurate seeking

**Disadvantages:**
- ❌ Very large file sizes (uncompressed)
- ❌ Slower rendering

**Configuration:**
```matlab
Parameters.animation_format = 'avi';
Parameters.animation_fps = 24;

% Uncompressed (lossless, huge files)
Parameters.animation_codec = 'Uncompressed AVI';

% Compressed (smaller, still large)
Parameters.animation_codec = 'Motion JPEG AVI';
```

**Output Example:**
```
vorticity_evolution_Nx128_Ny128_nu0.0010_dt0.0100_Tfinal8.0_ic_stretched_gaussian_mode_solve_20260127_153045.avi
Size: ~50-200 MB (uncompressed, 50 frames)
      ~5-20 MB (Motion JPEG, 50 frames)
```

---

## Frame Count Control

### Standard Analysis (9 frames default)
```matlab
Parameters.snap_times = linspace(0, Parameters.Tfinal, 9);
```
**Result:** Basic evolution overview, minimal computational cost

---

### Medium Resolution (50 frames)
```matlab
Parameters.snap_times = linspace(0, Parameters.Tfinal, 50);
```
**Result:** Smooth animation, good for presentations

---

### High Resolution (100-200 frames) - Animation Mode
```matlab
run_mode = "animation";
settings.animation.num_frames = 150;
```
**Result:** Publication-quality smooth evolution, shows fine temporal details

---

### Ultra-High Resolution (500+ frames)
```matlab
run_mode = "animation";
settings.animation.num_frames = 500;
```
**Result:** Frame-by-frame analysis capability, slow-motion effect  
**Warning:** High computational cost and memory usage

---

## Playback Speed Examples

### Slow Motion (Good for Analysis)
```matlab
settings.animation.num_frames = 200;  % Many frames
settings.animation.fps = 15;           % Slow playback
% Result: 13.3 second video showing fine details
```

---

### Real-Time (Good for Demonstrations)
```matlab
settings.animation.num_frames = 100;
settings.animation.fps = 30;
% Result: 3.33 second video, smooth playback
```

---

### Fast Overview (Good for Comparisons)
```matlab
settings.animation.num_frames = 50;
settings.animation.fps = 60;
% Result: 0.83 second video, quick overview
```

---

### Time-Lapse (Good for Long Simulations)
```matlab
Parameters.Tfinal = 100;              % Long simulation
settings.animation.num_frames = 300;   % Reasonable frame count
settings.animation.fps = 60;           % Fast playback
% Result: 5 second video covering 100 time units
```

---

## Animation Mode Workflow

### Step 1: Configure Parameters
```matlab
clc; close all; clear;

% Load utilities
addpath(genpath("C:\...\utilities"))

% Select animation mode
run_mode = "animation";

% Grid and physics
Parameters = struct;
Parameters.Lx = 10;
Parameters.Ly = 10;
Parameters.Nx = 256;  % High resolution for quality
Parameters.Ny = 256;
Parameters.nu = 1e-5;
Parameters.dt = 0.005;  % Small timestep for accuracy
Parameters.Tfinal = 10;
Parameters.ic_type = "stretched_gaussian";
Parameters.ic_coeff = [-2 -0.2];

% Animation settings
settings.animation.format = 'mp4';
settings.animation.fps = 30;
settings.animation.quality = 95;
settings.animation.num_frames = 200;  % Detailed evolution
```

---

### Step 2: Run Animation Mode
```matlab
[T, meta] = run_animation_mode(Parameters, settings, run_mode);
```

**Console Output:**
```
=== ANIMATION MODE ===
Creating high-resolution animation with 200 frames
Format: MP4 at 30 FPS

Vorticity animation saved as MP4: Figures/Finite Difference/Animations/vorticity_evolution_...mp4
Duration: 6.67 seconds at 30 FPS

Animation created successfully!
Frames: 200
Duration: 6.67 seconds
```

---

### Step 3: View and Analyze
```matlab
% Open in MATLAB
implay('Figures/Finite Difference/Animations/vorticity_evolution_....mp4')

% Or use external player (VLC, Windows Media Player, etc.)
winopen('Figures/Finite Difference/Animations/vorticity_evolution_....mp4')
```

---

## Best Practices

### For Presentations
```matlab
settings.animation.format = 'mp4';
settings.animation.fps = 24;
settings.animation.num_frames = 100;
settings.animation.quality = 85;
```
- Smooth playback
- Small file size for embedding
- Compatible with PowerPoint/Keynote

---

### For Publications
```matlab
settings.animation.format = 'mp4';
settings.animation.fps = 30;
settings.animation.num_frames = 150;
settings.animation.quality = 95;
```
- High quality
- Professional framerate
- Clear visualization of dynamics

---

### For Web Sharing
```matlab
settings.animation.format = 'gif';
settings.animation.fps = 15;
settings.animation.num_frames = 50;
```
- Auto-loops
- No codec needed
- Direct embed in markdown/HTML

---

### For Detailed Analysis
```matlab
settings.animation.format = 'avi';
settings.animation.codec = 'Uncompressed AVI';
settings.animation.fps = 60;
settings.animation.num_frames = 300;
```
- Lossless quality
- Frame-accurate seeking
- Post-processing ready

---

## Performance Considerations

### Computational Cost
| Frames | Resolution | Approximate Runtime | Memory Usage |
|--------|------------|---------------------|--------------|
| 9 | 128×128 | ~5 seconds | ~50 MB |
| 50 | 128×128 | ~25 seconds | ~200 MB |
| 100 | 256×256 | ~2 minutes | ~500 MB |
| 200 | 256×256 | ~4 minutes | ~1 GB |
| 500 | 512×512 | ~15 minutes | ~4 GB |

**Note:** Times assume standard desktop (Intel i7, 16 GB RAM)

---

### Storage Requirements
| Format | Frames | Quality | Typical File Size |
|--------|--------|---------|-------------------|
| GIF | 50 | 256 colors | 2-5 MB |
| GIF | 200 | 256 colors | 8-15 MB |
| MP4 | 50 | 85 | 500 KB - 1 MB |
| MP4 | 200 | 90 | 2-4 MB |
| MP4 | 500 | 95 | 5-10 MB |
| AVI (uncompressed) | 50 | Lossless | 50-100 MB |
| AVI (uncompressed) | 200 | Lossless | 200-400 MB |
| AVI (Motion JPEG) | 50 | High | 5-15 MB |

---

## Troubleshooting

### Issue: Animation file is huge
**Solution:**
1. Use MP4 instead of AVI
2. Reduce quality: `settings.animation.quality = 75`
3. Reduce frame count: `settings.animation.num_frames = 100`

---

### Issue: Animation playback is too fast/slow
**Solution:**
```matlab
% Adjust FPS independently of frame count
settings.animation.fps = 15;  % Slower
settings.animation.fps = 60;  % Faster
```

---

### Issue: Choppy animation
**Solution:**
1. Increase frame count: `settings.animation.num_frames = 200`
2. Reduce timestep: `Parameters.dt = 0.001` (smoother temporal resolution)
3. Use MP4/AVI (smoother interpolation than GIF)

---

### Issue: Video codec not available
**Error:** `Unable to create VideoWriter object with profile 'MPEG-4'`

**Solution:**
```matlab
% Try alternative codec
Parameters.animation_codec = 'Motion JPEG AVI';
Parameters.animation_format = 'avi';
```

---

### Issue: Colors look washed out in GIF
**Solution:** GIF is limited to 256 colors. Use MP4 for full color:
```matlab
settings.animation.format = 'mp4';
```

---

## Example Configurations

### Quick Preview (Development)
```matlab
settings.animation.format = 'gif';
settings.animation.fps = 10;
settings.animation.num_frames = 20;
```
Fast, small files for quick checks

---

### Standard Analysis
```matlab
settings.animation.format = 'mp4';
settings.animation.fps = 24;
settings.animation.num_frames = 100;
settings.animation.quality = 85;
```
Good balance of quality and file size

---

### Publication Quality
```matlab
settings.animation.format = 'mp4';
settings.animation.fps = 30;
settings.animation.num_frames = 200;
settings.animation.quality = 95;
```
High quality, smooth evolution

---

### Archival/Post-Processing
```matlab
settings.animation.format = 'avi';
settings.animation.codec = 'Uncompressed AVI';
settings.animation.fps = 60;
settings.animation.num_frames = 300;
```
Lossless, frame-accurate

---

## Summary

**Key Features:**
- ✅ Three formats: GIF, MP4, AVI
- ✅ Controllable playback speed (FPS)
- ✅ Configurable frame count (9 to 500+)
- ✅ Dedicated animation mode for high-resolution output
- ✅ Quality control for MP4 compression

**Recommended Settings:**
- **Presentations:** MP4, 24 FPS, 100 frames, quality 85
- **Publications:** MP4, 30 FPS, 150 frames, quality 95
- **Web:** GIF, 15 FPS, 50 frames
- **Analysis:** AVI uncompressed, 60 FPS, 300 frames

**Next Steps:**
1. Choose format based on use case
2. Set frame count and FPS for desired duration/smoothness
3. Run animation mode for high-quality output
4. View and analyze results
