"""
Main Application Window - Professional Tsunami Vortex Simulation Interface
Version: 3.0 - Dark Mode, Tabbed Layout, Responsive Panels
"""

from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QScrollArea,
    QSplitter, QLabel, QComboBox, QSpinBox, QDoubleSpinBox,
    QPushButton, QGroupBox, QFormLayout, QTabWidget, QTextEdit,
    QProgressBar, QFrame, QPlainTextEdit, QSizePolicy
)
from PySide6.QtCore import Qt, QThread, Signal
from PySide6.QtGui import QFont, QPixmap
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
import numpy as np
import sys
from pathlib import Path
from io import BytesIO

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from matlab_interface.engine_manager import MATLABEngineManager
from ui.results_analyzer import ResultsAnalyzer


class SimulationThread(QThread):
    """Background thread for running simulations"""
    progress = Signal(int)
    finished = Signal(dict)  # results dict
    error = Signal(str)

    def __init__(self, matlab_engine, params):
        super().__init__()
        self.matlab_engine = matlab_engine
        self.params = params

    def run(self):
        try:
            fig, metrics = self.matlab_engine.run_simulation(self.params)
            results = {'figure': fig, 'metrics': metrics, 'config': self.params}
            self.finished.emit(results)
        except Exception as e:
            self.error.emit(str(e))


class ICPreviewThread(QThread):
    """Background thread for IC preview generation"""
    finished = Signal(object)  # omega
    error = Signal(str)

    def __init__(self, ic_type, params, n_vortices, pattern, Lx, Ly, grid_size):
        super().__init__()
        self.ic_type = ic_type
        self.params = params
        self.n_vortices = n_vortices
        self.pattern = pattern
        self.Lx = Lx
        self.Ly = Ly
        self.grid_size = grid_size

    def run(self):
        try:
            omega = self._generate_ic()
            self.finished.emit(omega)
        except Exception as e:
            self.error.emit(str(e))

    def _generate_ic(self):
        """Generate IC field"""
        from utils.dispersion import disperse_vortices_py

        n = max(64, min(256, int(self.grid_size)))
        Lx = max(self.Lx, 1e-3)
        Ly = max(self.Ly, 1e-3)

        x = np.linspace(-Lx / 2, Lx / 2, n)
        y = np.linspace(-Ly / 2, Ly / 2, n)
        X, Y = np.meshgrid(x, y)

        omega = np.zeros_like(X)
        positions = disperse_vortices_py(self.n_vortices, self.pattern, Lx, Ly)

        if self.ic_type == 'Lamb-Oseen':
            gamma = self.params.get('gamma', 1.0)
            nu = self.params.get('nu', 0.1)
            t0 = self.params.get('t0', 1.0)
            for x0, y0 in positions:
                R2 = (X - x0) ** 2 + (Y - y0) ** 2
                omega += (gamma / (4 * np.pi * nu * t0)) * np.exp(-R2 / (4 * nu * t0))

        elif self.ic_type == 'Rankine':
            rc = self.params.get('core_radius', 0.5)
            core = np.zeros_like(X)
            for x0, y0 in positions:
                R = np.sqrt((X - x0) ** 2 + (Y - y0) ** 2)
                core += (R <= rc).astype(float)
            omega += core

        elif self.ic_type == 'Taylor-Green':
            k = self.params.get('wavenumber', 1.0)
            omega = 2 * k * np.sin(k * X) * np.sin(k * Y)
            if self.n_vortices > 1:
                for i in range(2, self.n_vortices + 1):
                    k_i = k * i
                    omega += (2 * k_i / i) * np.sin(k_i * X) * np.sin(k_i * Y)

        else:
            for x0, y0 in positions:
                omega += np.exp(-((X - x0) ** 2 + (Y - y0) ** 2) / 2)

        return omega / max(self.n_vortices, 1)


class TsunamiSimulationWindow(QMainWindow):
    """Main application window with professional interface"""

    def __init__(self):
        super().__init__()

        self.setWindowTitle('Tsunami Vortex Simulation - Professional Interface')
        self.setMinimumSize(1200, 800)
        self.resize(1600, 1000)
        self.setFont(QFont('Segoe UI', 10))
        self.setStyleSheet(self._get_stylesheet())

        # Initialize MATLAB engine
        self.matlab_engine = MATLABEngineManager(matlab_available=False)

        # Thread management
        self.sim_thread = None
        self.preview_thread = None

        # UI state
        self.results_analyzer = ResultsAnalyzer()

        # Create UI
        self.init_ui()

        # Initial preview
        self.update_ic_preview()

    def _get_stylesheet(self):
        """Return professional dark-mode stylesheet"""
        return """
            QMainWindow { background-color: #0f1115; color: #e6e6e6; }
            QLabel { color: #e6e6e6; }
            QGroupBox {
                border: 1px solid #2a2f3a;
                border-radius: 8px;
                margin-top: 12px;
                padding: 12px;
                font-weight: 600;
                color: #d8dee9;
            }
            QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 6px; }
            QPushButton {
                background-color: #3a7bd5;
                color: #ffffff;
                border: none;
                padding: 8px 14px;
                border-radius: 6px;
                font-weight: 600;
            }
            QPushButton:hover { background-color: #4b8fe6; }
            QPushButton:pressed { background-color: #2d66b8; }
            QPushButton:disabled { background-color: #2a2f3a; color: #9aa4b2; }
            QComboBox, QSpinBox, QDoubleSpinBox, QTextEdit, QPlainTextEdit {
                background-color: #12161d;
                border: 1px solid #2a2f3a;
                border-radius: 6px;
                padding: 6px;
                color: #e6e6e6;
                selection-background-color: #3a7bd5;
            }
            QComboBox::drop-down { border: 0px; }
            QScrollArea { border: none; background-color: transparent; }
            QTabWidget::pane { border: 1px solid #2a2f3a; top: -1px; }
            QTabBar::tab {
                background: #1a1d24;
                padding: 8px 16px;
                margin-right: 4px;
                border-top-left-radius: 6px;
                border-top-right-radius: 6px;
                color: #c9d1d9;
            }
            QTabBar::tab:selected { background: #222633; color: #ffffff; }
            QSplitter::handle { background-color: #20242e; }
            QProgressBar {
                border: 1px solid #2a2f3a;
                border-radius: 6px;
                text-align: center;
                color: #e6e6e6;
                background-color: #12161d;
            }
            QProgressBar::chunk { background-color: #3a7bd5; }
            QTableWidget { background-color: #12161d; color: #e6e6e6; gridline-color: #2a2f3a; }
            QHeaderView::section { background-color: #1a1d24; color: #e6e6e6; border: 1px solid #2a2f3a; padding: 4px; }
        """

    def init_ui(self):
        """Initialize the user interface"""
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(16, 16, 16, 16)
        main_layout.setSpacing(12)

        header = self._create_header()
        main_layout.addWidget(header)

        self.tabs = QTabWidget()
        self.tabs.addTab(self._create_settings_tab(), ' Settings')
        self.tabs.addTab(self._create_live_monitor_tab(), ' Live Monitor')
        self.tabs.addTab(self._create_figures_tab(), ' Figures')
        main_layout.addWidget(self.tabs)

    def _create_header(self):
        header = QWidget()
        layout = QHBoxLayout(header)
        layout.setContentsMargins(0, 0, 0, 0)

        title = QLabel('Tsunami Vortex Simulation')
        title.setStyleSheet('font-size: 18pt; font-weight: 700;')

        self.status_label = QLabel('Idle')
        self.status_label.setStyleSheet('color: #9aa4b2; font-size: 10pt;')

        layout.addWidget(title)
        layout.addStretch()
        layout.addWidget(self.status_label)
        return header

    def _create_settings_tab(self):
        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)

        splitter = QSplitter(Qt.Horizontal)

        left_panel = self._create_settings_panel()
        right_panel = self._create_preview_panel()

        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setSizes([520, 900])

        layout.addWidget(splitter)
        return container

    def _create_settings_panel(self):
        panel = QWidget()
        panel.setMinimumWidth(420)
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(0, 0, 0, 0)
        panel_layout.setSpacing(10)

        # Method group
        method_group = QGroupBox('Numerical Method')
        method_form = QFormLayout(method_group)
        self.method_combo = QComboBox()
        self.method_combo.addItems(['Finite Difference', 'Finite Volume', 'Spectral', 'Variable Bathymetry'])
        self.method_combo.currentTextChanged.connect(self.on_method_changed)
        method_form.addRow('Method:', self.method_combo)

        # Initial condition group
        ic_group = QGroupBox('Initial Conditions')
        ic_form = QFormLayout(ic_group)
        self.ic_combo = QComboBox()
        self.ic_combo.addItems(['Lamb-Oseen', 'Rankine', 'Taylor-Green', 'Lamb Dipole', 'Elliptical', 'Random'])
        self.ic_combo.currentTextChanged.connect(lambda: self.update_ic_preview())
        ic_form.addRow('IC Type:', self.ic_combo)

        self.pattern_combo = QComboBox()
        self.pattern_combo.addItems(['Single', 'Grid', 'Circular', 'Random'])
        self.pattern_combo.currentTextChanged.connect(lambda: self.update_ic_preview())
        ic_form.addRow('Pattern:', self.pattern_combo)

        self.n_vortices_spin = QSpinBox()
        self.n_vortices_spin.setRange(1, 20)
        self.n_vortices_spin.setValue(1)
        self.n_vortices_spin.valueChanged.connect(lambda: self.update_ic_preview())
        ic_form.addRow('Vortices:', self.n_vortices_spin)

        # Domain and grid
        domain_group = QGroupBox('Domain & Grid')
        domain_form = QFormLayout(domain_group)
        self.Lx_spin = QDoubleSpinBox()
        self.Lx_spin.setRange(1.0, 200.0)
        self.Lx_spin.setValue(10.0)
        self.Lx_spin.valueChanged.connect(lambda: self.update_ic_preview())
        domain_form.addRow('Domain Lx:', self.Lx_spin)

        self.Ly_spin = QDoubleSpinBox()
        self.Ly_spin.setRange(1.0, 200.0)
        self.Ly_spin.setValue(10.0)
        self.Ly_spin.valueChanged.connect(lambda: self.update_ic_preview())
        domain_form.addRow('Domain Ly:', self.Ly_spin)

        self.grid_spin = QSpinBox()
        self.grid_spin.setRange(32, 512)
        self.grid_spin.setValue(128)
        self.grid_spin.setSingleStep(32)
        self.grid_spin.valueChanged.connect(lambda: self.update_ic_preview())
        domain_form.addRow('Grid Size (N):', self.grid_spin)

        # Time parameters
        time_group = QGroupBox('Time & Physics')
        time_form = QFormLayout(time_group)
        self.dt_spin = QDoubleSpinBox()
        self.dt_spin.setRange(0.0001, 0.1)
        self.dt_spin.setValue(0.001)
        time_form.addRow('Time Step (dt):', self.dt_spin)

        self.t_final_spin = QDoubleSpinBox()
        self.t_final_spin.setRange(0.1, 1000.0)
        self.t_final_spin.setValue(10.0)
        time_form.addRow('Final Time (T):', self.t_final_spin)

        self.nu_spin = QDoubleSpinBox()
        self.nu_spin.setRange(0.0, 1.0)
        self.nu_spin.setValue(0.0001)
        self.nu_spin.setDecimals(5)
        time_form.addRow('Viscosity (nu):', self.nu_spin)

        panel_layout.addWidget(method_group)
        panel_layout.addWidget(ic_group)
        panel_layout.addWidget(domain_group)
        panel_layout.addWidget(time_group)
        panel_layout.addStretch()

        # Run controls
        run_group = QGroupBox('Execution')
        run_layout = QVBoxLayout(run_group)
        self.run_button = QPushButton(' Run Simulation')
        self.run_button.setFixedHeight(42)
        self.run_button.clicked.connect(self.run_simulation)
        run_layout.addWidget(self.run_button)

        self.progress_bar = QProgressBar()
        self.progress_bar.setVisible(False)
        run_layout.addWidget(self.progress_bar)
        panel_layout.addWidget(run_group)

        # Scroll wrapper
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setWidget(panel)

        scroll_container = QWidget()
        wrapper_layout = QVBoxLayout(scroll_container)
        wrapper_layout.setContentsMargins(0, 0, 0, 0)
        wrapper_layout.addWidget(scroll)

        return scroll_container

    def _create_preview_panel(self):
        panel = QWidget()
        panel.setMinimumWidth(620)
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)

        preview_group = QGroupBox('Initial Condition Preview')
        preview_layout = QVBoxLayout(preview_group)

        self.ic_canvas = FigureCanvas(Figure(figsize=(6, 5), facecolor='#10141b'))
        preview_layout.addWidget(self.ic_canvas)

        self.preview_info = QTextEdit()
        self.preview_info.setReadOnly(True)
        self.preview_info.setMinimumHeight(90)
        preview_layout.addWidget(self.preview_info)

        layout.addWidget(preview_group)

        summary_group = QGroupBox('Simulation Summary')
        summary_layout = QVBoxLayout(summary_group)
        self.summary_text = QTextEdit()
        self.summary_text.setReadOnly(True)
        self.summary_text.setText('Configure settings to generate a simulation summary.')
        summary_layout.addWidget(self.summary_text)
        layout.addWidget(summary_group)

        layout.addStretch()

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setWidget(panel)

        scroll_container = QWidget()
        wrapper_layout = QVBoxLayout(scroll_container)
        wrapper_layout.setContentsMargins(0, 0, 0, 0)
        wrapper_layout.addWidget(scroll)

        return scroll_container

    def _create_live_monitor_tab(self):
        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(0, 0, 0, 0)

        splitter = QSplitter(Qt.Horizontal)

        terminal_group = QGroupBox('MATLAB Terminal')
        terminal_layout = QVBoxLayout(terminal_group)
        self.terminal_output = QPlainTextEdit()
        self.terminal_output.setReadOnly(True)
        self.terminal_output.setLineWrapMode(QPlainTextEdit.LineWrapMode.NoWrap)
        self.terminal_output.setFont(QFont('Consolas', 10))
        terminal_layout.addWidget(self.terminal_output)
        splitter.addWidget(terminal_group)

        monitor_group = QGroupBox('Live Monitors')
        monitor_layout = QVBoxLayout(monitor_group)

        self.live_metrics_label = QLabel('Live metrics will appear here during runtime.')
        self.live_metrics_label.setStyleSheet('color: #9aa4b2;')
        monitor_layout.addWidget(self.live_metrics_label)

        self.monitor_canvas = FigureCanvas(Figure(figsize=(5, 4), facecolor='#10141b'))
        monitor_layout.addWidget(self.monitor_canvas)
        self._draw_monitor_placeholder()

        splitter.addWidget(monitor_group)
        splitter.setSizes([600, 700])

        content_layout.addWidget(splitter)
        content.setMinimumSize(1100, 650)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setWidget(content)

        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(scroll)
        return container

    def _create_figures_tab(self):
        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(10)

        figure_group = QGroupBox('Latest Simulation Figure')
        figure_layout = QVBoxLayout(figure_group)
        self.figure_image_label = QLabel('No figure available yet. Run a simulation to populate this view.')
        self.figure_image_label.setAlignment(Qt.AlignCenter)
        self.figure_image_label.setMinimumHeight(320)
        self.figure_image_label.setStyleSheet('color: #9aa4b2;')
        figure_layout.addWidget(self.figure_image_label)

        content_layout.addWidget(figure_group)
        content_layout.addWidget(self.results_analyzer)
        content.setMinimumSize(1100, 700)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.NoFrame)
        scroll.setWidget(content)

        container = QWidget()
        layout = QVBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(scroll)
        return container

    def _draw_monitor_placeholder(self):
        self.monitor_canvas.figure.clear()
        ax = self.monitor_canvas.figure.add_subplot(111)
        ax.set_facecolor('#10141b')
        ax.plot([0, 1], [0.5, 0.5], color='#3a7bd5', linewidth=2)
        ax.set_title('Live Metric Stream (placeholder)', color='#e6e6e6', fontsize=10)
        ax.set_xlabel('Time', color='#c9d1d9', fontsize=9)
        ax.set_ylabel('Value', color='#c9d1d9', fontsize=9)
        ax.tick_params(colors='#c9d1d9')
        ax.grid(True, alpha=0.2)
        self.monitor_canvas.figure.tight_layout()
        self.monitor_canvas.draw()

    def on_method_changed(self, text):
        """Handle method selection"""
        self._append_terminal(f'Method changed to: {text}')

    def update_ic_preview(self):
        """Update IC preview in background"""
        if self.preview_thread and self.preview_thread.isRunning():
            self.preview_thread.quit()
            self.preview_thread.wait()

        ic_type = self.ic_combo.currentText()
        n_vortices = self.n_vortices_spin.value()
        pattern = self.pattern_combo.currentText()
        Lx = self.Lx_spin.value()
        Ly = self.Ly_spin.value()
        grid_size = self.grid_spin.value()

        params = {
            'gamma': 1.0,
            'core_radius': 0.5,
            'wavenumber': 1.0,
            'nu': max(self.nu_spin.value(), 1e-6),
            't0': 1.0,
        }

        self._update_preview_info(ic_type, pattern, n_vortices, Lx, Ly, grid_size)

        self.preview_thread = ICPreviewThread(ic_type, params, n_vortices, pattern, Lx, Ly, grid_size)
        self.preview_thread.finished.connect(self._display_ic_preview)
        self.preview_thread.error.connect(self._on_preview_error)
        self.preview_thread.start()

    def _update_preview_info(self, ic_type, pattern, n_vortices, Lx, Ly, grid_size):
        info = (
            f'IC Type: {ic_type}\n'
            f'Pattern: {pattern}\n'
            f'Vortices: {n_vortices}\n'
            f'Domain: {Lx:.2f} x {Ly:.2f}\n'
            f'Preview Grid: {grid_size} x {grid_size}'
        )
        self.preview_info.setText(info)

        summary = (
            f'Method: {self.method_combo.currentText()}\n'
            f'N = {self.grid_spin.value()}\n'
            f'dt = {self.dt_spin.value():.4g}, T = {self.t_final_spin.value():.4g}\n'
            f'nu = {self.nu_spin.value():.4g}'
        )
        self.summary_text.setText(summary)

    def _display_ic_preview(self, omega):
        """Display IC preview"""
        self.ic_canvas.figure.clear()
        ax = self.ic_canvas.figure.add_subplot(111)
        ax.set_facecolor('#10141b')

        Lx = max(self.Lx_spin.value(), 1e-3)
        Ly = max(self.Ly_spin.value(), 1e-3)
        n = max(64, min(256, int(self.grid_spin.value())))
        x = np.linspace(-Lx / 2, Lx / 2, n)
        y = np.linspace(-Ly / 2, Ly / 2, n)

        im = ax.contourf(x, y, omega, levels=20, cmap='coolwarm')
        ax.contour(x, y, omega, levels=10, colors='#10141b', alpha=0.4, linewidths=0.6)

        ic_type = self.ic_combo.currentText()
        n_vortices = self.n_vortices_spin.value()
        title = f'{ic_type} - {n_vortices} Vortices (t=0)'
        ax.set_title(title, fontsize=11, fontweight='bold', color='#e6e6e6')
        ax.set_xlabel(r'$x$ [m]', fontsize=10, color='#c9d1d9')
        ax.set_ylabel(r'$y$ [m]', fontsize=10, color='#c9d1d9')
        ax.tick_params(colors='#c9d1d9')

        cbar = self.ic_canvas.figure.colorbar(im, ax=ax)
        cbar.set_label(r'$\omega$ [s$^{-1}$]', fontsize=9, color='#c9d1d9')
        cbar.ax.yaxis.set_tick_params(color='#c9d1d9')
        for label in cbar.ax.get_yticklabels():
            label.set_color('#c9d1d9')

        self.ic_canvas.figure.tight_layout()
        self.ic_canvas.draw()

    def _on_preview_error(self, error_msg):
        """Handle preview error"""
        self._append_terminal(f'Preview error: {error_msg}')

    def run_simulation(self):
        """Run simulation"""
        self.run_button.setEnabled(False)
        self.run_button.setText('Running...')
        self.progress_bar.setVisible(True)
        self.progress_bar.setValue(0)
        self.status_label.setText('Running simulation...')
        self._append_terminal('Starting simulation...')

        params = {
            'Method': self.method_combo.currentText(),
            'IC_type': self.ic_combo.currentText(),
            'Pattern': self.pattern_combo.currentText(),
            'N': self.grid_spin.value(),
            'n_vortices': self.n_vortices_spin.value(),
            'Lx': self.Lx_spin.value(),
            'Ly': self.Ly_spin.value(),
            'dt': self.dt_spin.value(),
            'T': self.t_final_spin.value(),
            'nu': self.nu_spin.value(),
        }

        self.sim_thread = SimulationThread(self.matlab_engine, params)
        self.sim_thread.finished.connect(self._on_simulation_finished)
        self.sim_thread.error.connect(self._on_simulation_error)
        self.sim_thread.start()

    def _on_simulation_finished(self, results):
        """Handle simulation completion"""
        self.run_button.setEnabled(True)
        self.run_button.setText(' Run Simulation')
        self.progress_bar.setVisible(False)
        self.status_label.setText('Simulation complete')
        self._append_terminal('Simulation complete.')

        self.results_analyzer.update_results(results)
        self._display_simulation_figure(results.get('figure'))

    def _display_simulation_figure(self, fig):
        if fig is None:
            self.figure_image_label.setText('No figure returned from simulation.')
            return

        if hasattr(fig, 'savefig'):
            try:
                buf = BytesIO()
                fig.savefig(buf, format='png', dpi=140, facecolor='#10141b')
                pixmap = QPixmap()
                pixmap.loadFromData(buf.getvalue())
                self.figure_image_label.setPixmap(pixmap)
                self.figure_image_label.setScaledContents(True)
                self.figure_image_label.setStyleSheet('border: 1px solid #2a2f3a;')
            except Exception as exc:
                self.figure_image_label.setText(f'Unable to render figure: {exc}')
        else:
            self.figure_image_label.setText('Simulation figure handle received (non-Matplotlib).')

    def _on_simulation_error(self, error_msg):
        """Handle simulation error"""
        self._append_terminal(f'Simulation error: {error_msg}')
        self.run_button.setEnabled(True)
        self.run_button.setText(' Run Simulation')
        self.progress_bar.setVisible(False)
        self.status_label.setText('Simulation error')

    def _append_terminal(self, message):
        if self.terminal_output is not None:
            self.terminal_output.appendPlainText(message)

    def closeEvent(self, event):
        """Cleanup on close"""
        if self.matlab_engine:
            self.matlab_engine.close()
        if self.sim_thread:
            self.sim_thread.quit()
            self.sim_thread.wait()
        if self.preview_thread:
            self.preview_thread.quit()
            self.preview_thread.wait()
        event.accept()
