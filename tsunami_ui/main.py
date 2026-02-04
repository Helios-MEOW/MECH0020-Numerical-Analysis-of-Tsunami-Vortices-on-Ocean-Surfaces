"""
Tsunami Vortex Simulation - Professional Qt Interface
Main entry point for the application

Run with: python main.py
"""

import sys
from PySide6.QtWidgets import QApplication
from ui.main_window import TsunamiSimulationWindow

def main():
    """Initialize and run the application"""
    app = QApplication(sys.argv)
    
    # Create main window
    window = TsunamiSimulationWindow()
    window.show()
    
    # Start event loop
    sys.exit(app.exec())

if __name__ == '__main__':
    main()
