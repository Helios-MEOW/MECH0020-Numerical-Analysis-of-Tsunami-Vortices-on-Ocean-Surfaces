"""
Python version of vortex dispersion utility
Mirrors the MATLAB disperse_vortices.m function
"""

import numpy as np

def disperse_vortices_py(n_vortices, pattern, Lx, Ly, min_dist=None):
    """
    Generate spatial positions for multiple vortices.
    
    Args:
        n_vortices (int): Number of vortices
        pattern (str): Distribution pattern ('single', 'circular', 'grid', 'random')
        Lx, Ly (float): Domain dimensions
        min_dist (float): Minimum separation for 'random' pattern
        
    Returns:
        list: List of (x, y) tuples for vortex positions
    """
    
    n_vortices = int(max(1, n_vortices))
    pattern = pattern.lower()
    
    # Single vortex at origin
    if n_vortices == 1 or pattern == 'single':
        return [(0.0, 0.0)]
    
    # Circular arrangement
    if pattern == 'circular':
        theta = np.linspace(0, 2*np.pi, n_vortices+1)[:-1]
        radius = min(Lx, Ly) / 4.0
        positions = [(radius * np.cos(t), radius * np.sin(t)) for t in theta]
        return positions
    
    # Grid arrangement
    if pattern == 'grid':
        n_cols = int(np.ceil(np.sqrt(n_vortices)))
        n_rows = int(np.ceil(n_vortices / n_cols))
        
        spacing_x = Lx / (n_cols + 1)
        spacing_y = Ly / (n_rows + 1)
        
        positions = []
        k = 0
        for i in range(n_rows):
            for j in range(n_cols):
                if k < n_vortices:
                    x = j * spacing_x - Lx/2
                    y = i * spacing_y - Ly/2
                    positions.append((x, y))
                    k += 1
        return positions
    
    # Random arrangement with minimum separation
    if pattern == 'random':
        if min_dist is None:
            min_dist = max(Lx, Ly) / 10.0
        
        positions = []
        max_attempts = 10000
        safety_counter = 0
        
        for i in range(n_vortices):
            placed = False
            attempts = 0
            
            while not placed and attempts < max_attempts:
                x_new = (np.random.random() - 0.5) * Lx * 0.9
                y_new = (np.random.random() - 0.5) * Ly * 0.9
                
                if len(positions) == 0:
                    valid = True
                else:
                    distances = [np.sqrt((x - x_new)**2 + (y - y_new)**2) 
                                for x, y in positions]
                    valid = all(d >= min_dist for d in distances)
                
                if valid:
                    positions.append((x_new, y_new))
                    placed = True
                
                attempts += 1
                safety_counter += 1
                
                if safety_counter > max_attempts * n_vortices:
                    print(f'Warning: Could not place all {n_vortices} vortices with minimum separation')
                    break
        
        return positions[:n_vortices]
    
    # Default: grid pattern
    print(f'Warning: Unknown pattern "{pattern}", using "grid"')
    return disperse_vortices_py(n_vortices, 'grid', Lx, Ly)
