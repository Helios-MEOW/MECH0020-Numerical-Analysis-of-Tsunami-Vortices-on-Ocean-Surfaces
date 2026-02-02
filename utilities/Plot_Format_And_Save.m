function Plot_Format_And_Save(X_Label_String, Y_Label_String, Title_String, FontSizes, Axis_LineWidth, Save_Flag, Current_Figure, File_Name, Resolution_Preset)
%PLOT_FORMAT_AND_SAVE Convenience wrapper to style + save.
%   Save_Flag optional; Resolution_Preset optional.

    if nargin < 6 || isempty(Save_Flag), Save_Flag = false; end
    if nargin < 5, Axis_LineWidth = []; end
    if nargin < 4, FontSizes = []; end

    Plot_Format(X_Label_String, Y_Label_String, Title_String, FontSizes, Axis_LineWidth);

    if Save_Flag
        if nargin < 9, Resolution_Preset = []; end
        Plot_Saver(Current_Figure, File_Name, Resolution_Preset);
    end
end