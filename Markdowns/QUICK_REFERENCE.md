# Energy Monitoring Quick Reference Card
## v4.1 Framework Commands & Workflows

---

## Installation (5 minutes)

```bash
# Install Python packages
pip install psutil numpy pandas

# Verify Python from MATLAB
>> pyenv('Version', 'C:\path\to\python.exe')
>> py.sys.version
```

---

## Basic Workflow

### 1. Start Monitoring
```matlab
Monitor = HardwareMonitorBridge();
Monitor.start_logging('my_experiment');
```

### 2. Run Simulation
```matlab
% ... your simulation code ...
```

### 3. Stop & Analyze
```matlab
log_file = Monitor.stop_logging();
stats = Monitor.get_statistics();

% Output includes:
%   .cpu_temp_mean, .cpu_temp_max
%   .power_mean, .power_max
%   .energy_joules, .energy_wh
%   .duration_seconds
```

---

## Building Energy Scaling Model

```matlab
analyzer = EnergySustainabilityAnalyzer();

% Add data points from different grid sizes
analyzer.add_data_from_log('log_128x128.csv', 128^2);
analyzer.add_data_from_log('log_256x256.csv', 256^2);
analyzer.add_data_from_log('log_512x512.csv', 512^2);

% Build model: E = A * C^α
analyzer.build_scaling_model();

% Predict future energy
E_1024 = analyzer.predict_energy(1024^2);

% Visualize
fig = analyzer.plot_scaling('title', 'Energy Scaling Study');

% Report
analyzer.generate_sustainability_report('report.json');
```

---

## Common Tasks

### View Sensor Data
```matlab
T = readtable('sensor_logs/experiment_20260127_120000_sensors.csv');
plot(T.timestamp - T.timestamp(1), T.power_consumption);
xlabel('Time (s)'); ylabel('Power (W)');
```

### Extract Energy Value
```matlab
T = readtable('log_file.csv');
power = T.power_consumption(~isnan(T.power_consumption));
dt = diff(T.timestamp(1:length(power)));
energy_joules = sum(power(1:end-1) .* dt);
energy_kwh = energy_joules / 3.6e6;
```

### Compare Multiple Runs
```matlab
Monitor = HardwareMonitorBridge();
comparison = Monitor.compare_runs({...
    'sensor_logs/config1_sensors.csv', ...
    'sensor_logs/config2_sensors.csv'}, ...
    {'Configuration A', 'Configuration B'});
```

### Compute Sustainability Metrics
```matlab
metrics = analyzer.compute_sustainability_metrics();

fprintf('Total Energy:        %.3f kWh\n', metrics.total_energy_kwh);
fprintf('Avg Efficiency:      %.2f J/point\n', metrics.efficiency_mean);
fprintf('CO2 Emissions:       %.3f kg CO2\n', metrics.co2_emissions_kg);
fprintf('Sustainability Score: %.1f / 100\n', metrics.sustainability_score);
```

---

## Energy Scaling Model Interpretation

| Value | Meaning | Assessment |
|-------|---------|-----------|
| α = 0.8 | Sub-linear | ✓ Excellent (scales better than linear) |
| α = 1.0 | Linear | ~ Good (expected for FD solvers) |
| α = 1.2 | Super-linear | ✗ Fair (scales worse than linear) |
| α = 1.5+ | Super-linear | ✗ Poor (investigate optimization) |

---

## Parameter Configuration

```matlab
% In Analysis.m:

Parameters.energy_monitoring.enabled = true;
Parameters.energy_monitoring.sample_interval = 0.5;  % seconds (2Hz)
Parameters.energy_monitoring.output_dir = 'sensor_logs';

Parameters.sustainability.build_model = true;
Parameters.sustainability.build_model_threshold = 3;  % min data points
```

---

## File Locations

```
Analysis/
├── hardware_monitor.py              # Python backend
├── HardwareMonitorBridge.m          # MATLAB bridge
├── EnergySustainabilityAnalyzer.m   # Analysis engine
└── sensor_logs/                     # Generated CSV files
    ├── evolution_20260127_120000_sensors.csv
    └── ...
```

---

## Troubleshooting Quick Fixes

| Issue | Solution |
|-------|----------|
| Python not available | `pyenv('Version', 'C:\path\to\python.exe')` |
| psutil not found | `pip install psutil numpy pandas` |
| Permission denied | `mkdir('sensor_logs')` |
| No temperature data | Optional (continues with other metrics) |
| NaN values | Check CPU load during simulation |

---

## Metrics Reference

### Hardware Metrics Logged
- `timestamp` — Unix timestamp
- `cpu_temp` — CPU temperature (°C)
- `cpu_frequency` — CPU frequency (MHz)
- `cpu_load` — CPU utilization (%)
- `ram_usage` — Memory used (MB)
- `ram_percent` — Memory utilization (%)
- `power_consumption` — Power draw (W)
- `power_limit` — Max power (W)

### Derived Metrics
- `energy_joules` = ∫ P dt
- `energy_wh` = energy_joules / 3600
- `energy_kwh` = energy_wh / 1000
- `efficiency` = energy / complexity
- `co2_kg` = energy_kwh × 0.5

### Computed Statistics
- `duration_seconds` — Total run time
- `power_mean` — Average power (W)
- `power_max` — Peak power (W)
- `cpu_temp_mean` — Average temperature (°C)
- `cpu_temp_max` — Peak temperature (°C)
- `sustainability_score` — 0-100 rating

---

## One-Liner Examples

```matlab
% Get energy from log file
E_J = sum(readtable('log.csv').power_consumption(1:end-1) .* diff(readtable('log.csv').timestamp));

% Build and plot model in one go
analyzer = EnergySustainabilityAnalyzer();
analyzer.add_data_from_log('l1.csv', 256); 
analyzer.add_data_from_log('l2.csv', 512);
analyzer.build_scaling_model(); 
analyzer.plot_scaling();

% Get statistics
stats = Monitor.get_statistics();
fprintf('Energy: %.1f J | Avg Power: %.1f W | Duration: %.1f s\n', ...
    stats.energy_joules, stats.power_mean, stats.duration_seconds);
```

---

## Configuration Examples

### Enable Detailed Monitoring
```matlab
Parameters.energy_monitoring.enabled = true;
Parameters.energy_monitoring.sample_interval = 0.1;  % 10 Hz (more data)
Parameters.sustainability.build_model = true;
```

### Disable Monitoring
```matlab
Parameters.energy_monitoring.enabled = false;
% Monitor won't be initialized, zero overhead
```

### Minimal Overhead
```matlab
Parameters.energy_monitoring.sample_interval = 2.0;  % 0.5 Hz (less frequent)
% Lower frequency = faster, less detailed
```

---

## Energy Calculation Examples

### Scenario 1: 256×256 Grid
```
Simulation duration: 100 seconds
Average power: 150 W
Energy: 150 W × 100 s = 15,000 J = 4.2 Wh = 0.0042 kWh
CO2: 0.0042 kWh × 0.5 kg/kWh = 0.0021 kg ≈ 5.3 m car driving
```

### Scenario 2: 512×512 Grid
```
Simulation duration: 500 seconds
Average power: 200 W
Energy: 200 W × 500 s = 100,000 J = 27.8 Wh = 0.0278 kWh
CO2: 0.0278 kWh × 0.5 kg/kWh = 0.0139 kg ≈ 35 m car driving
```

---

## Common Commands Reference

```matlab
% Initialize
Monitor = HardwareMonitorBridge();
Analyzer = EnergySustainabilityAnalyzer();

% Control monitoring
Monitor.start_logging('name');
log_file = Monitor.stop_logging();

% Get data
stats = Monitor.get_statistics();
metrics = Analyzer.compute_sustainability_metrics();

% Analysis
Analyzer.add_data_from_log(log_file, complexity);
Analyzer.build_scaling_model();
Analyzer.plot_scaling();

% Reports
Monitor.generate_report(output_file);
Analyzer.generate_sustainability_report(output_file);
comparison = Monitor.compare_runs(log_files, labels);

% Utilities
Analyzer.summarize_data();
E_predicted = Analyzer.predict_energy(new_complexity);
Monitor.correlate_with_simulation(sim_metrics);
```

---

## Checklist: First Test Run

- [ ] Python 3.8+ installed
- [ ] psutil, numpy, pandas installed
- [ ] MATLAB Python configured
- [ ] Files copied to Analysis/
- [ ] Analysis.m modified (STEP 1-2)
- [ ] Simple simulation runs
- [ ] sensor_logs/run_*.csv created
- [ ] CSV has power values (not all NaN)
- [ ] Can read log with readtable()
- [ ] Ready to scale up to full analysis

---

## Support

**For detailed help:**
- ENERGY_FRAMEWORK_GUIDE.md — Complete reference
- ENERGY_INTEGRATION_TEMPLATE.m — Copy-paste code
- VERSION_4_1_RELEASE_NOTES.md — Full documentation
- Hardware_monitor.py docstrings — Implementation details

**For quick help:**
- This card (overview)
- Inline comments in MATLAB/Python files

---

## Version Info

| Component | Version | Status |
|-----------|---------|--------|
| Framework | 4.1 | ✓ Released |
| Python module | 1.0 | ✓ Complete |
| MATLAB bridge | 1.0 | ✓ Complete |
| Analysis engine | 1.0 | ✓ Complete |
| Documentation | 1.0 | ✓ Complete |

**Last Updated:** January 27, 2026

---

Print this page and post next to your monitor! 📋⚡
