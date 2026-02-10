# Energy Sustainability & Hardware Monitoring Framework
## Complete Implementation Guide for v4.1

**Date:** January 27, 2026  
**Status:** Ready for Integration  
**Scope:** Hardware energy tracking + sustainability analysis for numerical solver

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation & Setup](#installation--setup)
4. [Integration with Analysis.m](#integration-with-analysism)
5. [Workflow Examples](#workflow-examples)
6. [Energy Scaling Model](#energy-scaling-model)
7. [Sustainability Reports](#sustainability-reports)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The Energy Sustainability Framework adds comprehensive hardware monitoring to your numerical solver, enabling you to:

- **Track real-time energy consumption** during simulations
- **Measure CPU temperature, power, and utilization** with 0.5s sampling
- **Build predictive models** for energy scaling with grid resolution
- **Quantify computational sustainability** and carbon footprint
- **Compare efficiency** across different simulation configurations

### Key Components

| Component | Language | Purpose |
|-----------|----------|---------|
| `hardware_monitor.py` | Python | Hardware sensor data collection & logging |
| `HardwareMonitorBridge.m` | MATLAB | MATLAB↔Python integration layer |
| `EnergySustainabilityAnalyzer.m` | MATLAB | Energy modeling & analysis |
| `sensor_logs/` | CSV | Hardware metrics database |

---

## Architecture

### Data Flow

```
MATLAB Simulation (Analysis.m)
    ↓
    ├─→ Start Hardware Monitor (Python subprocess)
    ├─→ Run Finite Difference Solver
    │   └─→ Compute vorticity field
    ├─→ Stop Hardware Monitor (collect sensor data)
    ├─→ Save Simulation Metrics (max_vorticity, convergence_rate, etc.)
    └─→ Correlate with Hardware Metrics
        ├─→ Energy: E = ∫P dt (Joules)
        ├─→ Temperature: avg, max
        ├─→ Power: mean, max (Watts)
        └─→ Efficiency: E / complexity

Python Hardware Monitor
    ├─→ psutil: CPU temp, frequency, load, memory
    ├─→ HWiNFO: Detailed sensor readings (if available)
    ├─→ CORSAIR iCUE: Cooling/device data (if available)
    └─→ Log to CSV: timestamp, temperature, power, load, etc.

Analysis Pipeline
    ├─→ Collect multiple runs (different grid sizes)
    ├─→ Build power-law model: E = A * C^α
    ├─→ Compute sustainability metrics
    └─→ Generate visualization & report
```

### System Requirements

**Python 3.8+:**
```
psutil              # System metrics (CPU, memory)
numpy               # Numerical analysis
pandas              # Data handling (optional but recommended)
```

**MATLAB:**
- R2023a or later (Python integration)
- Python configured with MATLAB

---

## Installation & Setup

### Step 1: Install Python Dependencies

```bash
pip install psutil numpy pandas
```

### Step 2: Configure MATLAB Python Environment

In MATLAB command window:
```matlab
% Check Python configuration
pyenv

% If not configured, set Python executable:
pyenv('Version', 'C:\path\to\python.exe')

% Verify connection
py.sys.version
```

### Step 3: Place Files in Analysis Directory

```
Analysis/
├── Analysis.m                              (existing, to be modified)
├── Finite_Difference_Analysis.m            (existing)
├── hardware_monitor.py                     (NEW)
├── HardwareMonitorBridge.m                 (NEW)
├── EnergySustainabilityAnalyzer.m          (NEW)
├── ENERGY_FRAMEWORK_GUIDE.md               (this file)
└── sensor_logs/                            (auto-created)
```

---

## Integration with Analysis.m

### Modification 1: Add Energy Monitoring Parameters

Insert after the visualization configuration (around line 160):

```matlab
%% ENERGY MONITORING CONFIGURATION
% ================================
Parameters.energy_monitoring = struct();
Parameters.energy_monitoring.enabled = true;          % Enable/disable
Parameters.energy_monitoring.sample_interval = 0.5;   % Seconds (2Hz)
Parameters.energy_monitoring.output_dir = 'sensor_logs';

% Sustainability analysis settings
Parameters.sustainability = struct();
Parameters.sustainability.build_model = true;         % Build E vs C model
Parameters.sustainability.auto_compare = false;       % Auto-compare runs
```

### Modification 2: Initialize Monitor in Mode Selection

In the `run_mode` switch statement (around line 280-350), add:

```matlab
% After mode initialization, always initialize monitor if enabled
if Parameters.energy_monitoring.enabled
    try
        Monitor = HardwareMonitorBridge();
        fprintf('[ENERGY] Hardware monitor initialized\n');
    catch ME
        warning('[ENERGY] Monitor initialization failed: %s', ME.message);
        Monitor = [];
    end
else
    Monitor = [];
end
```

### Modification 3: Start Monitoring Before Simulation

In each simulation mode block (e.g., `case "evolution"`), add:

```matlab
% Start energy monitoring
if ~isempty(Monitor) && Parameters.energy_monitoring.enabled
    log_filename = sprintf('%s_%s_%s', ...
        run_mode, datestr(now, 'yyyymmdd_HHMMSS'), ...
        sprintf('Nx%d_Ny%d', Nx, Ny));
    try
        Monitor.start_logging(log_filename);
        fprintf('[ENERGY] Logging started: %s\n', log_filename);
    catch ME
        warning('[ENERGY] Failed to start logging: %s', ME.message);
    end
end

% ... RUN YOUR SIMULATION CODE HERE ...
```

### Modification 4: Stop Monitoring & Analyze

After simulation completes, add:

```matlab
% Stop energy monitoring and correlate results
if ~isempty(Monitor) && Parameters.energy_monitoring.enabled
    try
        log_file = Monitor.stop_logging();
        fprintf('[ENERGY] Logging stopped\n');
        
        % Create simulation metrics structure
        sim_metrics = struct();
        sim_metrics.grid_size = Nx * Ny;
        sim_metrics.time_steps = nt;
        sim_metrics.max_vorticity = max(omega, [], 'all');
        sim_metrics.final_time = final_time;
        sim_metrics.viscosity = nu;
        
        % Correlate simulation with hardware metrics
        Monitor.correlate_with_simulation(sim_metrics);
        
    catch ME
        warning('[ENERGY] Analysis failed: %s', ME.message);
    end
end
```

---

## Workflow Examples

### Example 1: Simple Energy Tracking

```matlab
% Initialize
Parameters.energy_monitoring.enabled = true;
Monitor = HardwareMonitorBridge();

% Start simulation (monitor starts automatically with modified Analysis.m)
run_mode = "evolution";
Analysis;  % Runs your complete analysis

% View sensor log
log_file = 'sensor_logs/evolution_20260127_120000_sensors.csv';
T = readtable(log_file);
plot(T.timestamp - T.timestamp(1), T.power_consumption);
xlabel('Time (s)');
ylabel('Power (W)');
title('Power Consumption During Simulation');
```

### Example 2: Build Energy Scaling Model

```matlab
% Create analyzer
analyzer = EnergySustainabilityAnalyzer();

% Add measurements from different grid sizes
log_files = {
    'sensor_logs/EVOLUTION_20260127_120000_Nx128_Ny128_sensors.csv',
    'sensor_logs/EVOLUTION_20260127_120500_Nx256_Ny256_sensors.csv',
    'sensor_logs/EVOLUTION_20260127_121000_Nx512_Ny512_sensors.csv',
};

complexities = [128^2, 256^2, 512^2];  % Grid points

for i = 1:length(log_files)
    analyzer.add_data_from_log(log_files{i}, complexities(i));
end

% Build power-law model: E = A * C^α
analyzer.build_scaling_model();

% Compute sustainability metrics
metrics = analyzer.compute_sustainability_metrics();

% Plot results
fig = analyzer.plot_scaling('title', 'Vorticity Solver Energy Scaling');

% Predict energy for future runs
E_1024x1024 = analyzer.predict_energy(1024^2);
fprintf('Predicted energy for 1024×1024: %.0f J (%.3f kWh)\n', ...
    E_1024x1024, E_1024x1024/3.6e6);
```

### Example 3: Compare Multiple Configurations

```matlab
% Compare different viscosity values
configs = {'viscosity_1e-3', 'viscosity_1e-2', 'viscosity_1e-1'};
log_files = {
    'sensor_logs/viscosity_1e-3_sensors.csv',
    'sensor_logs/viscosity_1e-2_sensors.csv',
    'sensor_logs/viscosity_1e-1_sensors.csv',
};

Monitor = HardwareMonitorBridge();
comparison = Monitor.compare_runs(log_files, configs);

% Results show which configuration is most efficient
```

### Example 4: Sustainability Report

```matlab
% Generate comprehensive report
analyzer = EnergySustainabilityAnalyzer();

% Add your data
analyzer.add_data_from_log('sensor_logs/run1_sensors.csv', 256);
analyzer.add_data_from_log('sensor_logs/run2_sensors.csv', 512);
analyzer.build_scaling_model();

% Generate JSON report
analyzer.generate_sustainability_report('sustainability_report.json');

% Display summary
analyzer.summarize_data();
```

---

## Energy Scaling Model

### Power-Law Model: E = A × C^α

The framework fits a power-law relationship between energy and complexity:

**Model Equation:**
$$E = A \times C^\alpha$$

Where:
- **E** = Energy consumption (Joules)
- **C** = Computational complexity (grid points)
- **A** = Scaling coefficient
- **α** = Scaling exponent

### Interpretation of α

| Range | Interpretation | Implication |
|-------|-----------------|------------|
| **α < 1.0** | Sub-linear | Better efficiency at scale ✓ (preferred) |
| **α ≈ 1.0** | Linear | Energy scales with problem size (expected) |
| **α > 1.5** | Super-linear | Worse efficiency at scale ✗ (investigate) |

### Fitting Procedure

1. Collect energy measurements at different complexities
2. Transform to log-log space: ln(E) vs ln(C)
3. Linear regression: ln(E) = ln(A) + α×ln(C)
4. Report R² goodness-of-fit

**Example:**
```matlab
analyzer = EnergySustainabilityAnalyzer();
analyzer.add_data_point(256, 450);    % 256² grid, 450 J
analyzer.add_data_point(512, 1200);   % 512² grid, 1200 J
analyzer.add_data_point(1024, 3100);  % 1024² grid, 3100 J
analyzer.build_scaling_model();

% Output: E = 0.018 * C^1.09 (R² = 0.998)
% This is near-linear (expected for FD solver)
```

---

## Sustainability Reports

### Computed Metrics

```matlab
metrics = analyzer.compute_sustainability_metrics();

% metrics contains:
%   .total_energy_joules      - Sum of all energy consumption (J)
%   .total_energy_kwh         - Converted to kWh
%   .efficiency_mean          - Average J per unit complexity
%   .efficiency_trend         - Trend across runs (%)
%   .min_efficiency           - Best run
%   .max_efficiency           - Worst run
%   .sustainability_score     - 0-100 rating (100 = constant energy)
%   .co2_emissions_kg         - Estimated CO2 footprint
```

### JSON Report Format

```json
{
  "timestamp": "2026-01-27T12:34:56",
  "num_datapoints": 3,
  "scaling_model": {
    "A": 0.0182,
    "alpha": 1.089
  },
  "r_squared": 0.9982,
  "metrics": {
    "total_energy_joules": 4750,
    "total_energy_kwh": 0.00132,
    "co2_emissions_kg": 0.000659,
    "efficiency_mean": 7.24,
    "sustainability_score": 78.5
  },
  "data_points": [
    [65536, 450],
    [262144, 1200],
    [1048576, 3100]
  ]
}
```

---

## Hardware Monitoring Details

### Supported Sensors (psutil)

✓ **Always Available:**
- CPU load (%)
- CPU frequency (MHz)
- Memory usage (MB, %)
- Process metrics

⚠ **Platform Dependent:**
- CPU temperature (requires sensors-detect on Linux, native on Windows)
- Power consumption (estimated from CPU load; real data requires HWiNFO)

### External Tools (Windows Optional)

**HWiNFO64:**
- More detailed CPU/GPU temperature
- Power consumption from PSU monitoring
- Voltage rails
- Installation: [https://www.hwinfo.com](https://www.hwinfo.com)

**CORSAIR iCUE:**
- RGB cooling device temps
- Fan speeds
- Installation: [https://www.corsair.com/icue](https://www.corsair.com/icue)

### Logging Format (CSV)

```csv
timestamp,cpu_temp,cpu_frequency,cpu_load,ram_usage,ram_percent,power_consumption,power_limit,...
1705246800.123,52.5,3400.0,45.3,8192.5,32.1,156.2,350.0,...
1705246800.623,53.1,3400.0,48.7,8201.3,32.2,165.4,350.0,...
1705246801.123,52.8,3400.0,46.5,8198.1,32.1,159.3,350.0,...
```

---

## Troubleshooting

### Issue: "Python is not available"

**Solution:**
```matlab
% Check current Python
pyenv

% Configure Python (replace with your Python path)
pyenv('Version', 'C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe')

% Verify
py.sys.version
```

### Issue: Module Not Found (e.g., "No module named psutil")

**Solution:**
```bash
# Install missing packages
pip install psutil numpy pandas

# Verify installation
python -c "import psutil; print(psutil.cpu_percent())"
```

### Issue: Permission Denied Writing Logs

**Solution:**
```matlab
% Ensure sensor_logs directory exists and is writable
mkdir('sensor_logs');

% Or specify alternate directory
Parameters.energy_monitoring.output_dir = fullfile(pwd, 'results', 'sensor_logs');
mkdir(Parameters.energy_monitoring.output_dir);
```

### Issue: No CPU Temperature Readings

**Possible causes:**
- Temperature sensors not available on your system
- Requires elevated privileges on some systems
- Linux requires `lm-sensors` package

**Workaround:** System will continue logging other metrics (power, CPU load, memory)

### Issue: Inconsistent Power Measurements

**Note:** Power consumption is estimated from CPU load when real PSU data unavailable.

**For accurate power:**
1. Install HWiNFO64 with sensor monitoring
2. Configure HWiNFO to export CSV data
3. Integrate HWiNFO data into `hardware_monitor.py`

---

## Advanced: Custom Sensor Integration

### Adding HWiNFO Support

Edit `hardware_monitor.py` to implement HWiNFO sensor reading:

```python
def get_hwinfo_csv_data(self):
    """Extract real power data from HWiNFO CSV export"""
    # HWiNFO exports to: %AppData%\HWiNFO\CSV
    hwinfo_csv = Path.home() / 'AppData' / 'Roaming' / 'HWiNFO' / 'CSV'
    
    # Read latest CSV
    # Return power_consumption from PSU section
    pass
```

### Adding Custom Metric

In `EnergySustainabilityAnalyzer.m`:

```matlab
function custom_metric = compute_custom_efficiency(obj, baseline_config)
    % Example: Energy per iteration
    % baseline_config: reference configuration for comparison
    
    C = obj.data_points(:, 1);
    E = obj.data_points(:, 2);
    
    % Assume iterations = 1000 per configuration
    energy_per_iteration = E / 1000;
    
    custom_metric = struct(...
        'energy_per_iteration', energy_per_iteration, ...
        'relative_to_baseline', energy_per_iteration / baseline_energy);
end
```

---

## Quick Reference: Common Operations

```matlab
% ===== BASIC USAGE =====
Monitor = HardwareMonitorBridge();
Monitor.start_logging('experiment_name');
% ... run simulation ...
log_file = Monitor.stop_logging();

% ===== ANALYSIS =====
analyzer = EnergySustainabilityAnalyzer();
analyzer.add_data_from_log(log_file, complexity);
analyzer.build_scaling_model();
metrics = analyzer.compute_sustainability_metrics();

% ===== VISUALIZATION =====
fig = analyzer.plot_scaling('title', 'My Analysis');
analyzer.generate_sustainability_report('report.json');

% ===== COMPARISON =====
comparison = Monitor.compare_runs({log1, log2, log3}, {'A', 'B', 'C'});
```

---

## File Organization

```
Project Root
├── Analysis.m                      ← Main driver (MODIFIED for energy tracking)
├── Finite_Difference_Analysis.m    ← Solver (unchanged)
├── hardware_monitor.py             ← Python sensor backend (NEW)
├── HardwareMonitorBridge.m         ← MATLAB-Python bridge (NEW)
├── EnergySustainabilityAnalyzer.m  ← Energy analysis (NEW)
├── ENERGY_FRAMEWORK_GUIDE.md       ← This guide (NEW)
└── sensor_logs/                    ← Hardware log database (auto-created)
    ├── evolution_20260127_120000_Nx128_Ny128_sensors.csv
    ├── evolution_20260127_120500_Nx256_Ny256_sensors.csv
    └── ...
```

---

## Integration Checklist

- [ ] Python 3.8+ installed with psutil, numpy, pandas
- [ ] MATLAB Python environment configured
- [ ] `hardware_monitor.py` placed in Analysis directory
- [ ] `HardwareMonitorBridge.m` placed in Analysis directory
- [ ] `EnergySustainabilityAnalyzer.m` placed in Analysis directory
- [ ] Analysis.m modified with energy configuration parameters
- [ ] `sensor_logs/` directory created
- [ ] Test with simple simulation run
- [ ] Verify sensor logs created in `sensor_logs/`
- [ ] Build scaling model with multi-resolution tests
- [ ] Generate sustainability report

---

## References

- **Power-Law Scaling:** https://en.wikipedia.org/wiki/Power_law
- **Energy Efficiency:** https://en.wikipedia.org/wiki/Energy_efficiency
- **Carbon Footprint Estimation:** IPCC Climate Change 2021
- **psutil Documentation:** https://psutil.readthedocs.io/
- **HWiNFO:** https://www.hwinfo.com/

---

**Created:** January 27, 2026  
**Version:** 1.0  
**Contact:** Your Energy Research Team
