"""
MATLAB Engine Manager - Handles communication with MATLAB backend

If MATLAB Engine for Python is installed, this will connect to the MATLAB engine.
Otherwise, it provides a mock interface for testing.
"""

import warnings

class MATLABEngineManager:
    """Manages MATLAB engine lifecycle and function calls"""
    
    def __init__(self, matlab_available=False):
        """
        Initialize MATLAB engine
        
        Args:
            matlab_available (bool): Force use of mock engine if False
        """
        self.matlab_available = False
        self.eng = None
        
        try:
            if matlab_available:
                import matlab.engine
                print("Starting MATLAB Engine...")
                self.eng = matlab.engine.start_matlab()
                self.matlab_available = True
                
                # Add paths to MATLAB
                self.eng.addpath('Scripts/Methods', nargout=0)
                self.eng.addpath('Scripts/Infrastructure', nargout=0)
                print("MATLAB Engine initialized successfully")
        except ImportError:
            warnings.warn("MATLAB Engine for Python not installed. Using mock engine for testing.")
            self.matlab_available = False
    
    def run_simulation(self, params_dict):
        """
        Run simulation with given parameters
        
        Args:
            params_dict (dict): Simulation parameters
            
        Returns:
            tuple: (results_fig, analysis_metrics)
        """
        if self.matlab_available:
            try:
                # Convert Python dict to MATLAB struct
                matlab_params = self._dict_to_matlab_struct(params_dict)
                
                # Run simulation
                fig_handle, analysis = self.eng.run_simulation_with_method(
                    matlab_params, nargout=2
                )
                
                return fig_handle, analysis
            except Exception as e:
                raise RuntimeError(f"MATLAB simulation failed: {str(e)}")
        else:
            # Mock simulation result for testing
            return self._mock_simulation_result()
    
    def extract_metrics(self, analysis_struct):
        """
        Extract unified metrics from analysis structure
        
        Args:
            analysis_struct: MATLAB analysis structure
            
        Returns:
            dict: Extracted metrics
        """
        if self.matlab_available:
            metrics = self.eng.extract_unified_metrics(analysis_struct, nargout=1)
            return metrics
        else:
            return self._mock_metrics()
    
    def close(self):
        """Clean up MATLAB engine"""
        if self.eng is not None:
            self.eng.quit()
    
    # Internal helper methods
    
    def _dict_to_matlab_struct(self, params_dict):
        """Convert Python dict to MATLAB struct"""
        matlab_params = self.eng.struct()
        for key, value in params_dict.items():
            self.eng.setfield(matlab_params, key, value)
        return matlab_params
    
    def _mock_simulation_result(self):
        """Return mock results for testing without MATLAB"""
        # This is a placeholder for testing
        import numpy as np
        import matplotlib.pyplot as plt
        
        # Create sample plot
        fig, ax = plt.subplots(figsize=(8, 6))
        x = np.linspace(0, 2*np.pi, 100)
        y = np.sin(x)
        ax.plot(x, y, 'b-', linewidth=2)
        ax.set_xlabel(r'$x$ [m]', fontsize=12)
        ax.set_ylabel(r'$\omega$ [s$^{-1}$]', fontsize=12)
        ax.set_title(r'Vorticity: $\omega(x,t)$', fontsize=14)
        ax.grid(True, alpha=0.3)
        
        # Mock analysis result
        analysis = {
            'energy': 1.234,
            'enstrophy': 0.567,
            'time_steps': 1000,
            'computation_time': 12.34
        }
        
        return fig, analysis
    
        def _mock_simulation_result(self):
            """Return mock results for testing without MATLAB"""
            import numpy as np
            from matplotlib.figure import Figure
        
            # Create IC preview plot
            fig = Figure(figsize=(8, 6))
            ax = fig.add_subplot(111)
        
            # Generate mock vorticity field
            x = np.linspace(-5, 5, 128)
            y = np.linspace(-5, 5, 128)
            X, Y = np.meshgrid(x, y)
        
            # Lamb-Oseen-like vortex
            R = np.sqrt(X**2 + Y**2)
            omega = np.exp(-R**2 / 2)
        
            # Plot
            im = ax.contourf(x, y, omega, levels=20, cmap='RdBu_r')
            ax.contour(x, y, omega, levels=10, colors='black', alpha=0.2, linewidths=0.5)
            ax.set_xlabel(r'$x$ [m]', fontsize=11)
            ax.set_ylabel(r'$y$ [m]', fontsize=11)
            ax.set_title(r'Vorticity Field: $\omega(x,y,t)$', fontsize=12, fontweight='bold')
            cbar = fig.colorbar(im, ax=ax)
            cbar.set_label(r'$\omega$ [s$^{-1}$]', fontsize=10)
        
            # Mock metrics with realistic values
            analysis = {
                'energy': 1.2345,
                'enstrophy': 0.5678,
                'max_vorticity': 1.0000,
                'time_steps': 1000,
                'computation_time': 12.34,
                'num_threads': 4,
                'grid_size': 128,
            }
        
            return fig, analysis
    def _mock_metrics(self):
        """Return mock metrics for testing"""
        return {
            'energy_decay': 0.92,
            'error': 0.0123,
            'cpu_time': 12.34,
            'memory_used': 256.5
        }

    def __del__(self):
        """Cleanup on object deletion"""
        self.close()
