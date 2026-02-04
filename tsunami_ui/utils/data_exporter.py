"""
Data Export Module - Handles exporting simulation results in multiple formats
"""

import json
import csv
from pathlib import Path
from typing import Dict, Any
import numpy as np

class DataExporter:
    """Exports simulation results to various formats"""
    
    @staticmethod
    def export_json(results: Dict[str, Any], filepath: Path) -> bool:
        """Export results as JSON"""
        try:
            export_data = {
                'metadata': {
                    'format_version': '1.0',
                    'export_date': str(Path(filepath).stat().st_mtime),
                },
                'config': results.get('config', {}),
                'metrics': results.get('metrics', {}),
                'parameters': results.get('parameters', {}),
            }
            
            with open(filepath, 'w') as f:
                json.dump(export_data, f, indent=2, default=str)
            return True
        except Exception as e:
            print(f'JSON export error: {e}')
            return False
    
    @staticmethod
    def export_csv(results: Dict[str, Any], filepath: Path) -> bool:
        """Export metrics as CSV"""
        try:
            metrics = results.get('metrics', {})
            config = results.get('config', {})
            
            with open(filepath, 'w', newline='') as f:
                writer = csv.writer(f)
                
                # Header
                writer.writerow(['Parameter', 'Value'])
                
                # Configuration
                writer.writerow(['--- Configuration ---', ''])
                for key, val in config.items():
                    writer.writerow([key, val])
                
                # Metrics
                writer.writerow(['--- Metrics ---', ''])
                for key, val in metrics.items():
                    writer.writerow([key, val])
            
            return True
        except Exception as e:
            print(f'CSV export error: {e}')
            return False
    
    @staticmethod
    def export_hdf5(results: Dict[str, Any], filepath: Path) -> bool:
        """Export results as HDF5 (requires h5py)"""
        try:
            import h5py
            
            with h5py.File(filepath, 'w') as f:
                # Create groups
                config_group = f.create_group('config')
                metrics_group = f.create_group('metrics')
                
                # Save configuration
                config = results.get('config', {})
                for key, val in config.items():
                    try:
                        config_group[key] = val
                    except (TypeError, ValueError):
                        config_group[key] = str(val)
                
                # Save metrics
                metrics = results.get('metrics', {})
                for key, val in metrics.items():
                    try:
                        metrics_group[key] = val
                    except (TypeError, ValueError):
                        metrics_group[key] = str(val)
            
            return True
        except ImportError:
            print('h5py not installed. Install with: pip install h5py')
            return False
        except Exception as e:
            print(f'HDF5 export error: {e}')
            return False
    
    @staticmethod
    def export_results(results: Dict[str, Any], filepath: Path, format: str = 'auto') -> bool:
        """Export results in specified format"""
        filepath = Path(filepath)
        
        # Auto-detect format from extension
        if format == 'auto':
            suffix = filepath.suffix.lower()
            format_map = {
                '.json': 'json',
                '.csv': 'csv',
                '.h5': 'hdf5',
                '.hdf5': 'hdf5',
            }
            format = format_map.get(suffix, 'json')
        
        # Create parent directories
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Export
        if format == 'json':
            return DataExporter.export_json(results, filepath)
        elif format == 'csv':
            return DataExporter.export_csv(results, filepath)
        elif format == 'hdf5':
            return DataExporter.export_hdf5(results, filepath)
        else:
            print(f'Unknown format: {format}')
            return False
