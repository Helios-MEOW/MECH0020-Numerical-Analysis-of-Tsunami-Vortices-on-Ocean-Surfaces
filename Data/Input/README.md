# Data/Input - Reference Test Cases

This directory contains small reference test cases and input data files that are version-controlled.

## Purpose
- Store validated test cases for regression testing
- Provide example initial conditions
- Document expected input formats

## Guidelines
- Keep files small (< 1 MB preferred)
- Include metadata (grid size, parameters, source)
- Use descriptive filenames

## Suggested Structure
```
Data/Input/
├── test_cases/
│   ├── gaussian_vortex_64x64.mat
│   ├── lamb_oseen_128x128.mat
│   └── test_case_metadata.csv
├── bathymetry/
│   └── example_bathymetry.mat
└── validation/
    └── reference_solutions.mat
```

## Note
Generated outputs go to `Data/Output/` (gitignored).
