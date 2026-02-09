% ========================================================================
% ConsoleUtils - Console Output Utilities (Static Class)
% ========================================================================
% Console formatting and color output functions extracted from Analysis.m
% Used by: Analysis.m, convergence agents, monitoring systems
%
% Usage: ConsoleUtils.fprintf_colored('cyan', 'Message: %s\n', msg)
%
% Methods:
%   fprintf_colored(color_name, format_str, varargin) - Colored console output
%   strip_ansi_codes(text) - Remove ANSI escape codes from text
%
% Created: 2026-02-05
% Part of: Tsunami Vortex Analysis Framework
% ========================================================================

classdef ConsoleUtils
    methods(Static)
        function fprintf_colored(color_name, format_str, varargin)
            % Prints formatted text with consistent color support
            % Delegates to ColorPrintf for cross-platform colored output
            formatted_text = sprintf(format_str, varargin{:});

            % Map color_name to cprintf-compatible style
            color_map = struct(...
                'red',        '[0.8, 0.0, 0.0]', ...
                'green',      '[0.0, 0.7, 0.0]', ...
                'yellow',     '[0.85, 0.55, 0.0]', ...
                'blue',       '[0.0, 0.3, 0.8]', ...
                'magenta',    '[0.7, 0.0, 0.7]', ...
                'cyan',       '[0.0, 0.6, 0.8]', ...
                'white',      '[0.9, 0.9, 0.9]', ...
                'black',      '[0.0, 0.0, 0.0]');

            if isfield(color_map, lower(color_name))
                ColorPrintf.colored(color_map.(lower(color_name)), '%s', formatted_text);
            else
                fprintf('%s', formatted_text);
            end
        end
        
        function clean = strip_ansi_codes(text)
            % Remove ANSI color escape codes from text
            clean = regexprep(string(text), '\\x1b\[\d+m', '');
            clean = regexprep(clean, '\x1b\[\d+m', '');
        end
    end
end