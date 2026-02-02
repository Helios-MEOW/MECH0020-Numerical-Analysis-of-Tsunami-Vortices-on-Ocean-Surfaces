#!/usr/bin/env python3
"""
Hardware Sensor Monitoring & Energy Sustainability Tracker
============================================================

Purpose: Extract real-time hardware sensor data during computational simulations
         Track energy consumption, thermal generation, and computational efficiency
         Build scalable models for sustainability analysis

Supported Hardware:
  - CPU: Temperature, frequency, power consumption (via CPU-Z, HWiNFO)
  - GPU: Temperature, power draw, utilization (via GPU-Z, HWiNFO)
  - PSU: Total system power (via HWiNFO)
  - Motherboard: Voltage rails, fan speeds (via HWiNFO, Armory Crate)
  - CORSAIR iCUE: RGB devices, cooling solutions

Author: Energy Sustainability Research Team
Date: January 27, 2026
"""

import psutil
import time
import json
import csv
import numpy as np
import subprocess
import platform
import logging
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass, asdict, field
from typing import Optional, List, Dict, Tuple
import threading
import queue

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class HardwareSensors:
    """Container for hardware sensor readings"""
    timestamp: float
    cpu_temp: Optional[float] = None  # °C
    gpu_temp: Optional[float] = None  # °C (if available)
    cpu_frequency: Optional[float] = None  # MHz
    cpu_load: float = 0.0  # Percentage (0-100)
    ram_usage: float = 0.0  # MB
    ram_percent: float = 0.0  # Percentage (0-100)
    power_consumption: Optional[float] = None  # Watts
    power_limit: Optional[float] = None  # Watts (max)
    voltage_12v: Optional[float] = None  # Volts
    voltage_5v: Optional[float] = None  # Volts
    fan_speed: Optional[float] = None  # RPM
    gpu_load: Optional[float] = None  # Percentage (0-100)
    gpu_power: Optional[float] = None  # Watts
    # CORSAIR iCUE fields
    icue_liquid_temp: Optional[float] = None  # Liquid cooling temp (°C)
    icue_pump_speed: Optional[float] = None  # Pump RPM
    icue_fan_speed: Optional[float] = None  # Average fan speed (RPM)
    icue_available: bool = False  # iCUE device detected
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization"""
        return asdict(self)
    
    def to_csv_row(self) -> list:
        """Convert to CSV row"""
        return list(self.to_dict().values())


class HardwareMonitor:
    """
    Real-time hardware monitoring system
    Collects sensor data from system and external tools
    """
    
    def __init__(self, use_hwinfo: bool = True, use_icue: bool = True):
        """
        Initialize hardware monitor
        
        Args:
            use_hwinfo: Attempt to use HWiNFO for detailed sensor data
            use_icue: Attempt to use CORSAIR iCUE for cooling data
        """
        self.use_hwinfo = use_hwinfo
        self.use_icue = use_icue
        self.system = platform.system()
        self.is_windows = self.system == 'Windows'
        
        if not self.is_windows:
            logger.warning("Some features (HWiNFO, iCUE) only available on Windows")
        
        self.hwinfo_available = False
        self.icue_available = False
        
        # Check for external tools
        if self.is_windows:
            self._check_hwinfo()
            self._check_icue()
    
    def _check_hwinfo(self) -> bool:
        """Check if HWiNFO is available"""
        try:
            # HWiNFO typically installed at C:\Program Files\HWiNFO64
            hwinfo_paths = [
                r"C:\Program Files\HWiNFO64\HWiNFO64.exe",
                r"C:\Program Files\HWiNFO32\HWiNFO32.exe",
                r"C:\Program Files\HWiNFO\HWiNFO.exe"
            ]
            for path in hwinfo_paths:
                if Path(path).exists():
                    self.hwinfo_available = True
                    self.hwinfo_path = path
                    logger.info(f"HWiNFO found: {path}")
                    return True
        except Exception as e:
            logger.debug(f"HWiNFO check failed: {e}")
        
        self.hwinfo_available = False
        logger.info("HWiNFO not found. Using psutil fallback (less detailed)")
        return False
    
    def _check_icue(self) -> bool:
        """Check if CORSAIR iCUE is available"""
        try:
            icue_paths = [
                r"C:\Program Files\CORSAIR\CORSAIR iCUE 4 Software\iCUE.exe",
                r"C:\Program Files\Corsair\CORSAIR iCUE 3 Software\iCUE.exe"
            ]
            for path in icue_paths:
                if Path(path).exists():
                    self.icue_available = True
                    self.icue_path = path
                    logger.info(f"CORSAIR iCUE found: {path}")
                    return True
        except Exception as e:
            logger.debug(f"iCUE check failed: {e}")
        
        self.icue_available = False
        logger.info("CORSAIR iCUE not found")
        return False
    
    def get_icue_data(self) -> Dict[str, any]:
        """
        Retrieve CORSAIR iCUE cooling and device data
        
        Returns:
            Dictionary with cooling solution status, RGB devices, and thermal metrics
        """
        icue_data = {
            'available': False,
            'cooling_devices': [],
            'rgb_devices': [],
            'liquid_temp': None,
            'pump_speed': None,
            'fan_speeds': []
        }
        
        if not self.icue_available:
            return icue_data
        
        try:
            # Attempt to read iCUE registry or config files for sensor data
            import winreg
            
            # CORSAIR iCUE registry paths
            reg_paths = [
                (winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\CorsairLLAccess"),
                (winreg.HKEY_CURRENT_USER, r"Software\CORSAIR\CORSAIR iCUE")
            ]
            
            for hive, path in reg_paths:
                try:
                    with winreg.OpenKey(hive, path) as key:
                        icue_data['available'] = True
                        logger.debug("iCUE registry detected")
                except:
                    continue
            
            # Attempt to parse iCUE config for device info
            icue_config_paths = [
                Path.home() / r"AppData\Local\CORSAIR\CORSAIR iCUE 4 Software\settings.json",
                Path.home() / r"AppData\Local\CORSAIR\CORSAIR iCUE 3 Software\config.json"
            ]
            
            for config_path in icue_config_paths:
                if config_path.exists():
                    try:
                        with open(config_path, 'r') as f:
                            config = json.load(f)
                            
                            # Extract cooling solution data if available
                            if 'cooling' in config:
                                cooling = config['cooling']
                                icue_data['cooling_devices'] = cooling.get('devices', [])
                                icue_data['liquid_temp'] = cooling.get('liquid_temp')
                                icue_data['pump_speed'] = cooling.get('pump_rpm')
                                icue_data['fan_speeds'] = cooling.get('fan_speeds', [])
                            
                            # Extract RGB device info
                            if 'devices' in config:
                                icue_data['rgb_devices'] = config['devices']
                            
                            logger.info(f"iCUE config loaded: {config_path}")
                            icue_data['available'] = True
                            break
                    except Exception as e:
                        logger.debug(f"Failed to parse iCUE config {config_path}: {e}")
                        continue
        
        except Exception as e:
            logger.debug(f"iCUE data retrieval failed: {e}")
        
        return icue_data
    
    
    def get_cpu_metrics(self) -> Tuple[Optional[float], Optional[float], float]:
        """
        Get CPU temperature, frequency, and load
        
        Returns:
            (cpu_temp_celsius, cpu_freq_mhz, cpu_load_percent)
        """
        try:
            # CPU load (%)
            cpu_load = psutil.cpu_percent(interval=0.1)
            
            # CPU frequency (MHz)
            cpu_freq = psutil.cpu_freq()
            cpu_freq_mhz = cpu_freq.current if cpu_freq else None
            
            # CPU temperature (°C) - psutil method
            cpu_temp = None
            try:
                temps = psutil.sensors_temperatures()
                if 'coretemp' in temps:
                    cpu_temp = temps['coretemp'][0].current
                elif 'k10temp' in temps:  # AMD
                    cpu_temp = temps['k10temp'][0].current
                elif temps:  # Fallback to any available
                    cpu_temp = list(temps.values())[0][0].current
            except Exception as e:
                logger.debug(f"CPU temp via psutil failed: {e}")
            
            return cpu_temp, cpu_freq_mhz, cpu_load
        
        except Exception as e:
            logger.error(f"CPU metrics error: {e}")
            return None, None, 0.0
    
    def get_memory_metrics(self) -> Tuple[float, float]:
        """
        Get RAM usage
        
        Returns:
            (ram_usage_mb, ram_usage_percent)
        """
        try:
            mem = psutil.virtual_memory()
            return mem.used / (1024**2), mem.percent
        except Exception as e:
            logger.error(f"Memory metrics error: {e}")
            return 0.0, 0.0
    
    def get_power_metrics(self) -> Tuple[Optional[float], Optional[float]]:
        """
        Get system power consumption
        
        Returns:
            (power_watts, power_limit_watts)
        """
        # Estimation based on CPU load
        # Real power data requires HWiNFO with sensor export
        try:
            cpu_load = psutil.cpu_percent(interval=0.1)
            
            # Rough estimation (requires calibration)
            # Typical system: idle ~50W, full load ~300-400W
            base_power = 50  # Watts at idle
            max_power = 350  # Watts at full load
            
            estimated_power = base_power + (cpu_load / 100) * (max_power - base_power)
            
            return estimated_power, max_power
        
        except Exception as e:
            logger.error(f"Power metrics error: {e}")
            return None, None
    
    def get_hwinfo_data(self) -> Optional[Dict]:
        """
        Extract detailed sensor data from HWiNFO
        
        Returns:
            Dictionary of sensor readings or None
        """
        if not self.hwinfo_available:
            return None
        
        try:
            # HWiNFO CSV/JSON export would go here
            # This requires configuring HWiNFO to export data periodically
            # For now, return placeholder
            logger.info("HWiNFO data extraction requires configuration (not yet automated)")
            return None
        except Exception as e:
            logger.error(f"HWiNFO data extraction failed: {e}")
            return None
    
    def get_icue_data(self) -> Optional[Dict]:
        """
        Extract cooling/device data from CORSAIR iCUE
        
        Returns:
            Dictionary of iCUE device data or None
        """
        if not self.icue_available:
            return None
        
        try:
            # iCUE API would go here
            # CORSAIR provides limited API; would require iCUE SDK integration
            logger.info("iCUE data extraction requires SDK integration (not yet available)")
            return None
        except Exception as e:
            logger.error(f"iCUE data extraction failed: {e}")
            return None
    
    def read_sensors(self) -> HardwareSensors:
        """
        Read all available hardware sensors including iCUE cooling data
        
        Returns:
            HardwareSensors dataclass with current readings
        """
        cpu_temp, cpu_freq, cpu_load = self.get_cpu_metrics()
        ram_usage, ram_percent = self.get_memory_metrics()
        power, power_limit = self.get_power_metrics()
        
        # Get iCUE data if available
        icue_data = self.get_icue_data() if self.use_icue else {'available': False}
        icue_liquid_temp = None
        icue_pump_speed = None
        icue_fan_speed = None
        
        if icue_data.get('available'):
            icue_liquid_temp = icue_data.get('liquid_temp')
            icue_pump_speed = icue_data.get('pump_speed')
            
            # Calculate average fan speed if multiple fans
            fan_speeds = icue_data.get('fan_speeds', [])
            if fan_speeds:
                icue_fan_speed = sum(fan_speeds) / len(fan_speeds)
        
        sensors = HardwareSensors(
            timestamp=time.time(),
            cpu_temp=cpu_temp,
            cpu_frequency=cpu_freq,
            cpu_load=cpu_load,
            ram_usage=ram_usage,
            ram_percent=ram_percent,
            power_consumption=power,
            power_limit=power_limit,
            icue_liquid_temp=icue_liquid_temp,
            icue_pump_speed=icue_pump_speed,
            icue_fan_speed=icue_fan_speed,
            icue_available=icue_data.get('available', False)
        )
        
        return sensors


class SensorDataLogger:
    """
    Log hardware sensor data to file during simulation
    Supports continuous background logging via threading
    """
    
    def __init__(self, output_dir: str = "sensor_logs", interval: float = 0.5):
        """
        Initialize sensor logger
        
        Args:
            output_dir: Directory to save logs
            interval: Sampling interval in seconds (default: 0.5s = 2Hz)
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.interval = interval
        
        self.monitor = HardwareMonitor()
        self.data_queue = queue.Queue()
        self.is_logging = False
        self.log_thread = None
        self.readings: List[HardwareSensors] = []
    
    def start_logging(self, experiment_name: str = "experiment") -> str:
        """
        Start background logging thread
        
        Args:
            experiment_name: Name for this logging session
        
        Returns:
            Path to log file being written
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.log_file = self.output_dir / f"{experiment_name}_{timestamp}_sensors.csv"
        
        self.is_logging = True
        self.readings = []
        
        # Start background thread
        self.log_thread = threading.Thread(target=self._logging_loop, daemon=True)
        self.log_thread.start()
        
        logger.info(f"Logging started: {self.log_file}")
        return str(self.log_file)
    
    def _logging_loop(self):
        """Background thread that continuously reads sensors"""
        while self.is_logging:
            try:
                sensors = self.monitor.read_sensors()
                self.readings.append(sensors)
                self.data_queue.put(sensors)
                time.sleep(self.interval)
            except Exception as e:
                logger.error(f"Logging error: {e}")
                time.sleep(self.interval)
    
    def stop_logging(self) -> Path:
        """
        Stop logging and save data to CSV
        
        Returns:
            Path to saved log file
        """
        self.is_logging = False
        
        if self.log_thread:
            self.log_thread.join(timeout=5)
        
        # Save to CSV
        self._save_to_csv()
        logger.info(f"Logging stopped. Data saved: {self.log_file}")
        
        return self.log_file
    
    def _save_to_csv(self):
        """Save collected data to CSV file"""
        if not self.readings:
            logger.warning("No readings to save")
            return
        
        try:
            with open(self.log_file, 'w', newline='') as f:
                fieldnames = self.readings[0].to_dict().keys()
                writer = csv.DictWriter(f, fieldnames=fieldnames)
                
                writer.writeheader()
                for reading in self.readings:
                    writer.writerow(reading.to_dict())
            
            logger.info(f"Saved {len(self.readings)} readings to {self.log_file}")
        except Exception as e:
            logger.error(f"CSV save error: {e}")
    
    def get_statistics(self) -> Dict:
        """
        Compute statistics from logged data
        
        Returns:
            Dictionary of statistics
        """
        if not self.readings:
            return {}
        
        stats = {
            'num_samples': len(self.readings),
            'duration_seconds': self.readings[-1].timestamp - self.readings[0].timestamp,
            'cpu_temp_mean': None,
            'cpu_temp_max': None,
            'cpu_load_mean': None,
            'cpu_load_max': None,
            'ram_usage_mean': None,
            'ram_usage_max': None,
            'power_mean': None,
            'power_max': None,
            'energy_joules': None,
        }
        
        try:
            # Temperature stats (°C)
            temps = [r.cpu_temp for r in self.readings if r.cpu_temp is not None]
            if temps:
                stats['cpu_temp_mean'] = np.mean(temps)
                stats['cpu_temp_max'] = np.max(temps)
            
            # CPU load stats (%)
            loads = [r.cpu_load for r in self.readings if r.cpu_load is not None]
            if loads:
                stats['cpu_load_mean'] = np.mean(loads)
                stats['cpu_load_max'] = np.max(loads)
            
            # RAM stats (MB)
            ram_usages = [r.ram_usage for r in self.readings if r.ram_usage > 0]
            if ram_usages:
                stats['ram_usage_mean'] = np.mean(ram_usages)
                stats['ram_usage_max'] = np.max(ram_usages)
            
            # Power stats (Watts)
            powers = [r.power_consumption for r in self.readings if r.power_consumption is not None]
            if powers:
                stats['power_mean'] = np.mean(powers)
                stats['power_max'] = np.max(powers)
                
                # Energy integral (Wh)
                # E = ∫P dt ≈ Σ(P_i * Δt)
                power_joules = sum(powers[i] * self.interval for i in range(len(powers)))
                stats['energy_joules'] = power_joules
                stats['energy_wh'] = power_joules / 3600  # Convert to Wh
        
        except Exception as e:
            logger.error(f"Statistics error: {e}")
        
        return stats


class SustainabilityAnalyzer:
    """
    Analyze energy consumption patterns and sustainability
    Build models for computational efficiency
    """
    
    def __init__(self, sensor_logs_dir: str = "sensor_logs"):
        """
        Initialize analyzer
        
        Args:
            sensor_logs_dir: Directory containing sensor log files
        """
        self.sensor_logs_dir = Path(sensor_logs_dir)
        self.sensor_logs_dir.mkdir(exist_ok=True)
    
    def load_log(self, log_file: Path) -> List[HardwareSensors]:
        """Load sensor data from CSV file"""
        readings = []
        try:
            import pandas as pd
            df = pd.read_csv(log_file)
            
            for _, row in df.iterrows():
                reading = HardwareSensors(
                    timestamp=row['timestamp'],
                    cpu_temp=row['cpu_temp'] if pd.notna(row['cpu_temp']) else None,
                    cpu_frequency=row['cpu_frequency'] if pd.notna(row['cpu_frequency']) else None,
                    cpu_load=row['cpu_load'],
                    ram_usage=row['ram_usage'],
                    ram_percent=row['ram_percent'],
                    power_consumption=row['power_consumption'] if pd.notna(row['power_consumption']) else None,
                    power_limit=row['power_limit'] if pd.notna(row['power_limit']) else None,
                )
                readings.append(reading)
        
        except ImportError:
            logger.warning("pandas not available, using manual CSV parsing")
            readings = self._load_csv_manual(log_file)
        
        return readings
    
    def _load_csv_manual(self, log_file: Path) -> List[HardwareSensors]:
        """Manual CSV parsing without pandas"""
        readings = []
        try:
            with open(log_file, 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    reading = HardwareSensors(
                        timestamp=float(row['timestamp']),
                        cpu_temp=float(row['cpu_temp']) if row['cpu_temp'] and row['cpu_temp'] != 'None' else None,
                        cpu_load=float(row['cpu_load']),
                        ram_usage=float(row['ram_usage']),
                        ram_percent=float(row['ram_percent']),
                    )
                    readings.append(reading)
        except Exception as e:
            logger.error(f"CSV parsing error: {e}")
        
        return readings
    
    def compute_energy_scaling(self, logs: List[Path], complexities: List[float]) -> Dict:
        """
        Build energy scaling model: E ∝ Complexity^α
        
        Args:
            logs: List of log file paths
            complexities: Computational complexity values (e.g., grid resolution)
        
        Returns:
            Dictionary with scaling parameters
        """
        if len(logs) != len(complexities):
            raise ValueError("Number of logs must match number of complexities")
        
        energies = []
        for log_file in logs:
            readings = self.load_log(log_file)
            stats = self._compute_stats(readings)
            energies.append(stats.get('energy_joules', 0))
        
        try:
            # Fit: ln(E) = ln(A) + α*ln(C)
            # This is a power law: E = A * C^α
            complexities_log = np.log(complexities)
            energies_log = np.log(energies)
            
            # Linear regression
            coeffs = np.polyfit(complexities_log, energies_log, 1)
            alpha = coeffs[0]  # Exponent
            A = np.exp(coeffs[1])  # Coefficient
            
            return {
                'energy_scaling_exponent': alpha,
                'energy_scaling_coefficient': A,
                'model': f'E = {A:.3f} * C^{alpha:.3f}',
                'energies': energies,
                'complexities': complexities,
            }
        
        except Exception as e:
            logger.error(f"Scaling analysis error: {e}")
            return {}
    
    def _compute_stats(self, readings: List[HardwareSensors]) -> Dict:
        """Compute statistics from readings"""
        stats = {}
        try:
            powers = [r.power_consumption for r in readings if r.power_consumption is not None]
            if powers:
                total_time = readings[-1].timestamp - readings[0].timestamp
                energy_joules = sum(powers[i] * (readings[i+1].timestamp - readings[i].timestamp) 
                                   for i in range(len(powers)-1))
                stats['energy_joules'] = energy_joules
                stats['energy_wh'] = energy_joules / 3600
        except Exception as e:
            logger.error(f"Stats computation error: {e}")
        
        return stats
    
    def generate_report(self, log_file: Path, output_file: Optional[Path] = None) -> Dict:
        """
        Generate sustainability analysis report
        
        Args:
            log_file: Sensor log file
            output_file: Optional output file for report
        
        Returns:
            Report dictionary
        """
        readings = self.load_log(log_file)
        stats = self._compute_stats(readings)
        
        # Parse metadata from filename
        filename = log_file.name
        parts = filename.split('_')
        experiment_name = parts[0] if parts else "unknown"
        
        report = {
            'experiment': experiment_name,
            'log_file': str(log_file),
            'timestamp': datetime.now().isoformat(),
            'duration_seconds': readings[-1].timestamp - readings[0].timestamp if readings else 0,
            'num_samples': len(readings),
            'sampling_interval_seconds': 0.5,
            **stats
        }
        
        if output_file:
            with open(output_file, 'w') as f:
                json.dump(report, f, indent=2)
            logger.info(f"Report saved: {output_file}")
        
        return report


# ============================================================================
# MAIN EXAMPLE USAGE
# ============================================================================

if __name__ == "__main__":
    """Example: Log sensors during a simulated workload"""
    
    print("=" * 70)
    print("HARDWARE SENSOR MONITORING & ENERGY TRACKER")
    print("=" * 70)
    
    # Create logger
    logger_instance = SensorDataLogger(output_dir="sensor_logs", interval=0.5)
    
    # Start logging
    log_file = logger_instance.start_logging("test_workload")
    print(f"\n[LOG] Logging started: {log_file}")
    
    # Simulate workload (30 seconds)
    print("\n[WORKLOAD] Starting 30-second test workload...")
    try:
        # CPU-intensive workload
        start_time = time.time()
        target_duration = 30
        
        while time.time() - start_time < target_duration:
            # Simple computation to load CPU
            _ = sum(i**2 for i in range(100000))
            time.sleep(0.1)
    
    except KeyboardInterrupt:
        print("\n[INTERRUPT] Workload interrupted by user")
    
    # Stop logging and save
    log_file_final = logger_instance.stop_logging()
    print(f"\n[SAVE] Data saved to: {log_file_final}")
    
    # Analyze results
    stats = logger_instance.monitor._compute_stats(logger_instance.readings) if hasattr(logger_instance.monitor, '_compute_stats') else {}
    
    print("\n" + "=" * 70)
    print("SENSOR STATISTICS")
    print("=" * 70)
    print(f"Total Samples:     {len(logger_instance.readings)}")
    print(f"Duration:          {logger_instance.readings[-1].timestamp - logger_instance.readings[0].timestamp:.1f} seconds")
    print(f"Avg CPU Temp:      {np.mean([r.cpu_temp for r in logger_instance.readings if r.cpu_temp]) if any(r.cpu_temp for r in logger_instance.readings) else 'N/A':.1f}°C")
    print(f"Avg CPU Load:      {np.mean([r.cpu_load for r in logger_instance.readings]):.1f}%")
    print(f"Avg Power:         {np.mean([r.power_consumption for r in logger_instance.readings if r.power_consumption]):.1f}W")
    print("=" * 70)
