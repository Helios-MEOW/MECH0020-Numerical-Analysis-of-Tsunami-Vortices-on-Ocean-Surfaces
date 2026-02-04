"""
Results Analysis Module - Handles simulation results visualization and export
"""

from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLabel,
    QTabWidget, QTableWidget, QTableWidgetItem, QFileDialog
)
from PySide6.QtCore import Qt, Signal
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import numpy as np
from datetime import datetime

class ResultsAnalyzer(QWidget):
    """Widget for analyzing and displaying simulation results"""

    export_requested = Signal(dict)

    def __init__(self):
        super().__init__()
        self.results = None
        self.metrics_history = []
        self.init_ui()

    def init_ui(self):
        """Initialize UI"""
        layout = QVBoxLayout()

        # Title
        title = QLabel('Results Analysis')
        title.setStyleSheet('font-size: 12pt; font-weight: 600;')
        layout.addWidget(title)

        # Tabs
        tabs = QTabWidget()

        # Plots tab
        self.canvas = FigureCanvas(Figure(figsize=(8, 6), facecolor='#10141b'))
        tabs.addTab(self.canvas, ' Plots')

        # Metrics tab
        self.metrics_table = QTableWidget()
        self.metrics_table.setColumnCount(2)
        self.metrics_table.setHorizontalHeaderLabels(['Metric', 'Value'])
        tabs.addTab(self.metrics_table, ' Metrics')

        # History tab
        self.history_table = QTableWidget()
        self.history_table.setColumnCount(5)
        self.history_table.setHorizontalHeaderLabels(['Time', 'Method', 'N', 'Energy', 'Time(s)'])
        tabs.addTab(self.history_table, ' History')

        layout.addWidget(tabs)

        # Export button
        export_btn = QPushButton(' Export Results')
        export_btn.clicked.connect(self.export_results)
        layout.addWidget(export_btn)

        self.setLayout(layout)

    def update_results(self, results_dict):
        """Update results display"""
        self.results = results_dict

        # Update metrics
        metrics = results_dict.get('metrics', {})
        self._display_metrics(metrics)

        # Update plots
        self._plot_results(results_dict)

        # Add to history
        self._add_to_history(results_dict)

    def _display_metrics(self, metrics):
        """Display metrics table"""
        self.metrics_table.setRowCount(len(metrics))

        for row, (key, value) in enumerate(metrics.items()):
            self.metrics_table.setItem(row, 0, QTableWidgetItem(str(key)))

            if isinstance(value, float):
                self.metrics_table.setItem(row, 1, QTableWidgetItem(f'{value:.6f}'))
            else:
                self.metrics_table.setItem(row, 1, QTableWidgetItem(str(value)))

    def _plot_results(self, results):
        """Plot simulation results"""
        self.canvas.figure.clear()
        ax = self.canvas.figure.add_subplot(111)
        ax.set_facecolor('#10141b')

        metrics = results.get('metrics', {})

        # Create a simple bar chart of metrics
        keys = list(metrics.keys())[:5]  # Top 5 metrics
        values = [metrics.get(k, 0) for k in keys]

        bars = ax.bar(range(len(keys)), values, color=['#3a7bd5', '#4b8fe6', '#5ba2f2', '#7cb6f5', '#a3cdf8'])
        ax.set_xticks(range(len(keys)))
        ax.set_xticklabels(keys, rotation=30, ha='right', color='#c9d1d9')
        ax.set_ylabel('Value', fontweight='bold', color='#c9d1d9')
        ax.set_title('Simulation Metrics', fontweight='bold', fontsize=11, color='#e6e6e6')
        ax.tick_params(colors='#c9d1d9')
        ax.grid(True, alpha=0.2, axis='y')

        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            ax.text(
                bar.get_x() + bar.get_width() / 2.0,
                height,
                f'{height:.2f}',
                ha='center',
                va='bottom',
                fontsize=8,
                color='#c9d1d9'
            )

        self.canvas.figure.tight_layout()
        self.canvas.draw()

    def _add_to_history(self, results):
        """Add results to history"""
        config = results.get('config', {})
        metrics = results.get('metrics', {})

        row = self.history_table.rowCount()
        self.history_table.insertRow(row)

        self.history_table.setItem(row, 0, QTableWidgetItem(datetime.now().strftime('%H:%M:%S')))
        self.history_table.setItem(row, 1, QTableWidgetItem(config.get('Method', 'N/A')))
        self.history_table.setItem(row, 2, QTableWidgetItem(str(config.get('N', 'N/A'))))
        self.history_table.setItem(row, 3, QTableWidgetItem(f'{metrics.get("energy", 0):.6f}'))
        self.history_table.setItem(row, 4, QTableWidgetItem(f'{metrics.get("computation_time", 0):.2f}'))

    def export_results(self):
        """Export results to file"""
        file_path, _ = QFileDialog.getSaveFileName(
            self, 'Export Results', '',
            'HDF5 Files (*.h5);;CSV Files (*.csv);;JSON Files (*.json)'
        )

        if file_path and self.results:
            self.export_requested.emit({'file': file_path, 'results': self.results})
