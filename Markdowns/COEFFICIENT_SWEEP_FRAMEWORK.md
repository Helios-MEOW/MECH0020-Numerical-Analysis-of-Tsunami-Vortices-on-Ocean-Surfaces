# Experimentation Mode: Coefficient Sweep Framework

**Date:** January 28, 2026  
**Status:** ✅ Complete Implementation  
**Framework Version:** 1.0

---

## Overview

The coefficient sweep framework enables systematic parametric studies of initial condition coefficients in the experimentation mode. This allows you to explore how changes in vortex properties (circulation, radius, position, etc.) affect the flow evolution.

---

## Quick Start

### Enable a Coefficient Sweep

```matlab
% In Analysis.m, around line 190-240:

% 1. Choose which sweep to enable
experimentation.coefficient_sweep.vortex_pair_gamma.enabled = true;

% 2. Run Analysis normally
run_mode = "experimentation";
Analysis;  % Will automatically execute the sweep
```

### Available Pre-Configured Sweeps

| Sweep Name | Base Case | Parameter | What It Does |
|-----------|-----------|-----------|-------------|
| `vortex_pair_gamma` | Double Vortex | Circulation magnitude | Varies vortex strength from 0.5 to 2.5 |
| `vortex_pair_radius` | Double Vortex | Core radius | Varies vortex core size from 0.5 to 2.5 |
| `vortex_pair_separation` | Double Vortex | Distance between vortices | Varies separation from 2.0 to 6.0 |
| `stretched_gaussian_x` | Non-uniform BC | X-stretching | Varies x-distortion from 0.5 to 3.0 |
| `stretched_gaussian_y` | Non-uniform BC | Y-stretching | Varies y-distortion from 0.5 to 3.0 |
| `multi_param_sensitivity` | Counter-rotating | Multiple params | Joint variation of circulation and radius |

---

## Coefficient Sweep Structure

### Structure Definition

```matlab
sweep_config = struct();
sweep_config.enabled = false;              % Enable/disable this sweep
sweep_config.base_case = 'double_vortex';  % Which test case to use
sweep_config.parameter = 'gamma';          % Name of parameter being varied
sweep_config.index = 1;                    % Index in ic_coeff vector (scalar or array)
sweep_config.values = [0.5, 1.0, 1.5];    % Array of values to test
sweep_config.mode = 'absolute';            % 'absolute', 'relative', 'additive'
sweep_config.description = '...';          % Descriptive text
```

### Field Descriptions

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `enabled` | logical | Turn sweep on/off | `true` or `false` |
| `base_case` | string | Test case to modify | `'double_vortex'` |
| `parameter` | string | Parameter name (for labels) | `'gamma'`, `'radius'` |
| `index` | int or array | Position(s) in ic_coeff | `1` or `[3, 6]` |
| `values` | numeric array | Values to test | `[0.5:0.5:2.5]` |
| `mode` | string | How to apply variations | `'absolute'`, `'relative'`, `'additive'` |
| `description` | string | What this sweep does | `'Circulation magnitude sweep'` |

### Index Reference by Test Case

#### Double Vortex (vortex_pair)
```
ic_coeff = [Gamma1, R1, x1, y1, Gamma2, x2, y2]
           [  1    , 2 , 3 , 4 ,   5  , 6 , 7 ]

Example:
  index=1: Circulation of first vortex
  index=2: Core radius of first vortex
  index=3,6: x-positions (for separation sweep)
```

#### Three Vortex System
```
ic_coeff = [Gamma1, R1, x1, y1, Gamma2, R2, x2, y2, Gamma3, x3, y3]
           [  1   , 2 , 3 , 4 ,   5   , 6 , 7 , 8 ,   9   ,10 ,11 ]
```

#### Stretched Gaussian
```
ic_coeff = [x_coeff, y_coeff]
           [   1   ,    2    ]

Example:
  index=1: X-direction stretching
  index=2: Y-direction stretching
```

#### Counter-Rotating Pair
```
ic_coeff = [G1, R1, x1, y1, G2, R2, x2, y2]
           [ 1,  2,  3,  4,  5,  6,  7,  8 ]
```

---

## Configuration Examples

### Example 1: Simple Single-Parameter Sweep

```matlab
% Sweep circulation magnitude of vortex pair
experimentation.coefficient_sweep.vortex_pair_gamma = struct( ...
    'enabled', true, ...
    'base_case', 'double_vortex', ...
    'parameter', 'gamma', ...
    'index', 1, ...
    'values', [0.5, 1.0, 1.5, 2.0, 2.5], ...
    'description', 'Circulation magnitude sweep');
```

**What happens:**
- Base ic_coeff: `[1.0, 2.0, 3.0, 7.0, -1.5, 2.5]`
- Test 1: `[0.5, 2.0, 3.0, 7.0, -1.5, 2.5]` → ω_max reduced
- Test 2: `[1.0, 2.0, 3.0, 7.0, -1.5, 2.5]` → baseline
- Test 3: `[1.5, 2.0, 3.0, 7.0, -1.5, 2.5]` → stronger vortex
- Test 4: `[2.0, 2.0, 3.0, 7.0, -1.5, 2.5]` → more intense
- Test 5: `[2.5, 2.0, 3.0, 7.0, -1.5, 2.5]` → maximum strength

---

### Example 2: Multi-Index Separation Distance Sweep

```matlab
% Sweep separation distance of vortex pair
experimentation.coefficient_sweep.vortex_pair_separation = struct( ...
    'enabled', true, ...
    'base_case', 'double_vortex', ...
    'parameter', 'separation', ...
    'index', [3, 6], ...              % Affects both x1 and x2
    'mode', 'relative', ...           % Scale both by factor
    'values', [2.0, 3.0, 4.0, 5.0], ...
    'description', 'Vortex pair separation');
```

**What happens:**
- Base x-positions: `x1=3.0, x2=2.5` (separation=0.5)
- Value 2.0: Both x-positions scaled by 2.0 → `x1=6.0, x2=5.0`
- Value 3.0: Both scaled by 3.0 → `x1=9.0, x2=7.5`
- etc.

---

### Example 3: Multi-Parameter Sensitivity Study

```matlab
% Vary multiple parameters simultaneously
experimentation.coefficient_sweep.multi_param_sensitivity = struct( ...
    'enabled', true, ...
    'base_case', 'counter_rotating', ...
    'parameters', {{ ...
        struct('name', 'gamma1', 'index', 1, 'values', [1.0, 1.5, 2.0], 'mode', 'absolute'), ...
        struct('name', 'gamma2', 'index', 5, 'values', [-1.0, -1.5, -2.0], 'mode', 'absolute') ...
    }}, ...
    'description', 'Joint circulation sensitivity');
```

**What happens:**
- Creates all combinations: 3 gamma1 values × 3 gamma2 values = **9 simulations**
- Each combination tested independently
- Results table shows interaction effects

---

## Coefficient Variation Modes

### Absolute Mode
Direct assignment of parameter value:

```matlab
mode = 'absolute';
base_coeff = [1.0, 2.0, 3.0];
index = 1;
value = 1.5;

result = [1.5, 2.0, 3.0]  % index 1 replaced with value
```

### Relative Mode
Scale parameter by multiplication factor:

```matlab
mode = 'relative';
base_coeff = [1.0, 2.0, 3.0];
index = 1;
value = 2.0;  % Scale factor

result = [2.0, 2.0, 3.0]  % base_coeff(1) * 2.0 = 2.0
```

### Additive Mode
Add offset to parameter:

```matlab
mode = 'additive';
base_coeff = [1.0, 2.0, 3.0];
index = 2;
value = 0.5;  % Offset

result = [1.0, 2.5, 3.0]  % base_coeff(2) + 0.5 = 2.5
```

---

## Execution Flow

### When You Run Analysis with Sweep Enabled

```
1. Analysis.m starts
2. Detects: run_mode = "experimentation"
3. Checks: Is sweep.enabled == true?
   YES → Launch run_coefficient_sweep()
   NO → Run single test case only

4. run_coefficient_sweep() execution:
   ├─ For each value in sweep_config.values:
   │  ├─ Modify ic_coeff at specified index
   │  ├─ Run FD simulation
   │  ├─ Extract metrics (peak_omega, enstrophy, etc.)
   │  ├─ Save results to sweep_results cell array
   │  └─ Print progress line
   │
   ├─ Convert results to table
   ├─ Create summary figures
   │  ├─ Peak vorticity vs parameter
   │  ├─ Enstrophy vs parameter
   │  ├─ Computational time vs parameter
   │  └─ Peak speed vs parameter
   │
   └─ Return sweep_results, sweep_table

5. Results saved in:
   - Figures/[METHOD]/SWEEP/[TYPE]/
   - Output CSV with sweep summary
```

---

## Output and Results

### Sweep Results Structure

Each sweep generates:

**`sweep_results` (Cell Array)**
- Each cell contains a result struct for one parameter value
- Fields: `sweep_index`, `parameter_name`, `parameter_value`, `peak_abs_omega`, `enstrophy`, `wall_time_s`, etc.

**`sweep_table` (MATLAB Table)**
```
sweep_index  parameter_value  peak_abs_omega  enstrophy  peak_speed  wall_time_s
-----------  ---------------  --------------  ---------  ----------  -----------
      1           0.5            0.7234          0.1203      1.2345       25.3
      2           1.0            1.0456          0.2104      1.8934       26.1
      3           1.5            1.3201          0.3421      2.3421       27.8
      4           2.0            1.6789          0.4782      2.8901       29.2
      5           2.5            2.0123          0.6234      3.2341       30.5
```

### Visualization Output

Automatically creates figure with 4 subplots:
1. **Peak Vorticity vs Parameter** - Shows how maximum vorticity changes
2. **Enstrophy vs Parameter** - Shows total rotational energy
3. **Computational Cost vs Parameter** - Wall time per simulation
4. **Peak Speed vs Parameter** - Maximum flow velocity

---

## Custom Sweep Creation

### Template for New Sweep

```matlab
% Add to line 190-240 in Analysis.m

experimentation.coefficient_sweep.my_custom_sweep = struct( ...
    'enabled', false, ...                              % Change to true to enable
    'base_case', 'double_vortex', ...                 % Choose base case
    'parameter', 'my_param', ...                       % Parameter name
    'index', [1], ...                                  % Index in ic_coeff
    'values', [val1, val2, val3, ...], ...            % Test values
    'mode', 'absolute', ...                            % 'absolute'/'relative'/'additive'
    'description', 'My custom parametric study');      % Description
```

### Custom Sweep via Code

```matlab
% Run programmatically without editing config
sweep_config = struct();
sweep_config.enabled = true;
sweep_config.base_case = 'double_vortex';
sweep_config.parameter = 'gamma';
sweep_config.index = 1;
sweep_config.values = linspace(0.1, 3.0, 20);  % 20 points
sweep_config.description = 'Fine-grained gamma sweep';

[results, table] = run_coefficient_sweep(test_cases.double_vortex, sweep_config, Parameters, settings);
```

---

## Helper Functions Reference

### `run_coefficient_sweep()`

```matlab
[sweep_results, sweep_table] = run_coefficient_sweep(...
    base_case,      % Test case struct (from test_cases)
    sweep_config,   % Sweep configuration struct
    Parameters,     % Main Parameters struct
    settings        % Visualization/save settings
);
```

**Returns:**
- `sweep_results` - Cell array of result structs
- `sweep_table` - Table with all metrics

### `plot_coefficient_sweep()`

```matlab
plot_coefficient_sweep(sweep_table, sweep_config);
```

Automatically creates 2×2 figure with analysis plots.

### `apply_coefficient_variation()`

```matlab
variant = apply_coefficient_variation(...
    base_coeff,      % Original ic_coeff vector
    variation_spec   % Struct with {index, value, mode}
);
```

**Example:**
```matlab
spec = struct('index', [3, 6], 'value', 4.0, 'mode', 'relative');
variant = apply_coefficient_variation([1, 2, 3, 7, -1.5, 2.5], spec);
```

---

## Common Use Cases

### Use Case 1: How Does Vortex Strength Affect Decay Rate?

```matlab
experimentation.coefficient_sweep.vortex_pair_gamma.enabled = true;
experimentation.coefficient_sweep.vortex_pair_gamma.values = linspace(0.1, 3.0, 15);

% Results show enstrophy decay vs circulation
% Helps understand energy dissipation dependence
```

### Use Case 2: Optimal Vortex Separation for Merger

```matlab
experimentation.coefficient_sweep.vortex_pair_separation.enabled = true;
experimentation.coefficient_sweep.vortex_pair_separation.values = [1.5:0.5:6.0];

% Results show which separation allows/prevents merger
% Guides design of coastal barriers
```

### Use Case 3: Anisotropic Stretching Effects

```matlab
experimentation.coefficient_sweep.stretched_gaussian_x.enabled = true;
experimentation.coefficient_sweep.stretched_gaussian_x.values = [0.5, 1.0, 1.5, 2.0, 2.5];

% Compare x-stretching impact
% Then run y-stretching sweep
% Understand directional dependence
```

### Use Case 4: Multi-Parameter Optimization

```matlab
experimentation.coefficient_sweep.multi_param_sensitivity.enabled = true;

% Joint variation of gamma1 and gamma2
% Creates response surface for optimization
% Identify parameter interactions
```

---

## Tips and Tricks

### Tip 1: Progressive Refinement

Start with coarse sweep, then refine:

```matlab
% First run: wide range, few points
values_coarse = [0.5, 1.0, 1.5, 2.0, 2.5];

% Later run: narrow range, many points
values_fine = linspace(1.0, 1.5, 20);
```

### Tip 2: Relative vs Absolute Modes

- **Absolute:** Good for physical parameters with known units
- **Relative:** Good for scaling studies (2× strength, 3× separation)

```matlab
% Absolute: Change gamma to specific values
'index', 1, 'mode', 'absolute', 'values', [0.5, 1.0, 1.5, 2.0];

% Relative: Scale gamma by factors
'index', 1, 'mode', 'relative', 'values', [0.5, 1.0, 1.5, 2.0];
```

### Tip 3: Parallel Execution (Future Enhancement)

```matlab
% Currently sequential - could be parallelized:
parfor i = 1:n_values
    % Run each sweep value on different core
    [results{i}] = execute_simulation(p_variant);
end
```

### Tip 4: Sensitivity Analysis Matrix

For multi-parameter studies, create interaction matrix:

```matlab
gamma_vals = [1.0, 1.5, 2.0];
radius_vals = [0.5, 1.0, 1.5];

results = zeros(length(gamma_vals), length(radius_vals));

for i = 1:length(gamma_vals)
    for j = 1:length(radius_vals)
        % Run with gamma_vals(i) and radius_vals(j)
        results(i,j) = feature_of_interest;
    end
end

% Plot as heatmap to visualize interaction effects
imagesc(results);
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Unknown test case" error | Check test case name matches exactly |
| Sweep doesn't run | Verify `enabled = true` in configuration |
| Wrong values tested | Check `index` matches correct position in ic_coeff |
| Unexpected parameter changes | Verify coefficient vector structure for your test case |
| Out of memory | Reduce number of values or enable figure closing after save |

---

## Integration with Other Modes

The coefficient sweep framework can be combined with:

| Framework | Integration |
|-----------|-------------|
| **Energy Monitoring** | Sweep results include energy metrics |
| **Convergence Study** | Use different grid resolutions in sweep |
| **Animation** | Generate animations for each swept value |
| **Parallel Computing** | Parallelize sweep loop across cores |

---

## Future Enhancements

- [ ] Multi-dimensional parameter space sampling (Design of Experiments)
- [ ] Response surface modeling (surrogate models)
- [ ] Automatic optimal value detection
- [ ] GPU acceleration for parallel sweeps
- [ ] Interactive GUI for sweep configuration
- [ ] Sensitivity analysis and gradient computation

---

## Contact & Support

For questions about coefficient sweeps:
- See [MATHEMATICAL_FRAMEWORK.md](MATHEMATICAL_FRAMEWORK.md) for IC definitions
- Check test case definitions in `run_experimentation_mode()` function
- Review `apply_coefficient_variation()` for custom variations

**Document Version:** 1.0  
**Last Updated:** January 28, 2026
