function Plot_Format(X_Label_String, Y_Label_String, Title_String, FontSizes, Axis_LineWidth)
%PLOT_FORMAT Standard plot styling for LaTeX-ready figures.
%   Plot_Format(xlabel, ylabel, title, FontSizes, Axis_LineWidth)
%   - FontSizes: cell {xFont, yFont, titleFont} or "Default" (falls back to Plot_Defaults)
%   - Axis_LineWidth: numeric; defaults from Plot_Defaults if omitted/empty

    d = Plot_Defaults();

    % Font sizes
    if nargin < 4 || isempty(FontSizes)
        FontSizes = d.FontSizes;
    elseif isstring(FontSizes) || ischar(FontSizes)
        if FontSizes == "Default"
            FontSizes = d.FontSizes;  % explicit default
        else
            % Allow a custom single value or triplet encoded as a string
            nums = str2double(regexp(string(FontSizes), "[-+]?[0-9]*\.?[0-9]+", "match"));
            if isempty(nums)
                FontSizes = d.FontSizes;
            elseif numel(nums) == 1
                FontSizes = {nums, nums, nums};
            else
                nums = nums(:).';
                if numel(nums) >= 3
                    FontSizes = num2cell(nums(1:3));
                else
                    FontSizes = d.FontSizes;
                end
            end
        end
    end

    % Axis line width
    if nargin < 5 || isempty(Axis_LineWidth)
        Axis_LineWidth = d.AxisLineWidth;
    end

    ax = gca;
    ax.XAxis.FontSize = FontSizes{1};
    ax.YAxis.FontSize = FontSizes{2};
    ax.Title.FontSize = FontSizes{3};
    ax.LineWidth = Axis_LineWidth;
    ax.Color = d.FigureColor;
    ax.GridColor = d.GridColor;
    ax.GridLineWidth = d.GridLineWidth;
    grid on; grid minor; box on
    ax.TickLabelInterpreter = d.TickInterpreter;
    xlabel(X_Label_String, "Interpreter", "latex");
    ylabel(Y_Label_String, "Interpreter", "latex");
    title(Title_String, "Interpreter", "latex");
end