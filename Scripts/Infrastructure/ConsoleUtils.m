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
            % Prints formatted text with consistent color support across MATLAB/terminals
            is_matlab = usejava('desktop');
            ansi_codes = struct(...
                'red', '\x1b[31m', 'green', '\x1b[32m', 'yellow', '\x1b[33m', ...
                'blue', '\x1b[34m', 'magenta', '\x1b[35m', 'cyan', '\x1b[36m', ...
                'white', '\x1b[37m', 'black', '\x1b[30m', ...
                'red_bg', '\x1b[41m\x1b[37m', 'yellow_bg', '\x1b[43m\x1b[30m', ...
                'cyan_bg', '\x1b[46m\x1b[30m', 'green_bg', '\x1b[42m\x1b[37m', ...
                'magenta_bg', '\x1b[45m\x1b[30m', 'blue_bg', '\x1b[44m\x1b[37m', ...
                'reset', '\x1b[0m');
            formatted_text = sprintf(format_str, varargin{:});
            if is_matlab
                clean_text = ConsoleUtils.strip_ansi_codes(formatted_text);
                fprintf('%s', clean_text);
            else
                if isfield(ansi_codes, color_name)
                    fprintf('%s%s%s', ansi_codes.(color_name), formatted_text, ansi_codes.reset);
                else
                    fprintf('%s', formatted_text);
                end
            end
        end
        
        function clean = strip_ansi_codes(text)
            % Remove ANSI color escape codes from text
            clean = regexprep(string(text), '\\x1b\[\d+m', '');
        end
    end
end