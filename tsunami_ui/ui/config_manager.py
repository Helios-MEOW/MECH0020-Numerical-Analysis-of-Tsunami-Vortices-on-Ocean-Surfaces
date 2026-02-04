"""
Configuration Manager - Handles saving/loading simulation configurations
"""

import json
from pathlib import Path
from typing import Dict, Any

class ConfigurationManager:
    """Manages simulation configurations"""
    
    DEFAULT_CONFIG = {
        'method': 'Finite Difference',
        'ic_type': 'Lamb-Oseen',
        'pattern': 'Single',
        'n_vortices': 1,
        'Lx': 10.0,
        'Ly': 10.0,
        'N': 128,
        'dt': 0.001,
        'T': 10.0,
        'nu': 0.0001,
    }
    
    def __init__(self, config_dir: Path = None):
        """Initialize configuration manager"""
        self.config_dir = config_dir or Path.home() / '.tsunami_ui'
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.config_file = self.config_dir / 'last_config.json'
    
    def load_config(self) -> Dict[str, Any]:
        """Load configuration from disk"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                print(f'Error loading config: {e}')
        
        return self.DEFAULT_CONFIG.copy()
    
    def save_config(self, config: Dict[str, Any]) -> bool:
        """Save configuration to disk"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
            return True
        except Exception as e:
            print(f'Error saving config: {e}')
            return False
    
    def get_preset_configs(self) -> Dict[str, Dict[str, Any]]:
        """Get preset configurations"""
        return {
            'Quick Test': {
                'method': 'Finite Difference',
                'ic_type': 'Lamb-Oseen',
                'pattern': 'Single',
                'N': 64,
                'T': 1.0,
            },
            'Standard': {
                'method': 'Finite Difference',
                'ic_type': 'Lamb-Oseen',
                'pattern': 'Grid',
                'N': 128,
                'T': 10.0,
                'n_vortices': 4,
            },
            'High Resolution': {
                'method': 'Spectral',
                'ic_type': 'Lamb-Oseen',
                'pattern': 'Circular',
                'N': 256,
                'T': 10.0,
                'n_vortices': 6,
            },
            'Convergence Study': {
                'method': 'Finite Difference',
                'ic_type': 'Taylor-Green',
                'pattern': 'Single',
                'N': 128,
                'T': 1.0,
                'dt': 0.0001,
            },
        }
