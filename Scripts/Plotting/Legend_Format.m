function Legend_Handle = Legend_Format(Legend_Entries, FontSize, Orientation, NumColumns, NumRows, AutoLocation, BoxOption, Padding, LocationOverride)
%LEGEND_FORMAT Styled legend with optional auto-placement.
%   Legend_Format(entries, FontSize, Orientation, NumColumns, NumRows,
%                 AutoLocation, BoxOption, Padding, LocationOverride)
%   - LocationOverride (optional): explicit legend location when AutoLocation=false

    d = Plot_Defaults();

    % --- Default argument values ---
    if nargin < 9, LocationOverride = d.Legend.LocationOverride; end
    if nargin < 8, Padding = d.Legend.Padding; end
    if nargin < 7, BoxOption = d.Legend.BoxOption; end
    if nargin < 6 || isempty(AutoLocation), AutoLocation = d.Legend.AutoLocation; end
    if nargin < 5 || isempty(NumRows), NumRows = d.Legend.NumRows; end
    if nargin < 4 || isempty(NumColumns), NumColumns = d.Legend.NumColumns; end
    if nargin < 3 || isempty(Orientation), Orientation = d.Legend.Orientation; end
    if nargin < 2 || isempty(FontSize), FontSize = d.Legend.FontSize; end
    if isempty(NumRows), NumRows = numel(Legend_Entries); end

    % --- Failsafe: single string → cell array ---
    if ischar(Legend_Entries) || isstring(Legend_Entries)
        Legend_Entries = {Legend_Entries};
    end

    Ax = gca;
    Ax.Units = "normalized";
    Hold_State = ishold(Ax);
    hold(Ax, "on");

    Legend_Handle = legend(Legend_Entries, "Interpreter", "latex");
    Legend_Handle.FontSize = FontSize;
    Legend_Handle.Box = BoxOption;
    Legend_Handle.Color = [1,1,1];
    Legend_Handle.EdgeColor = [0 0 0];

    % --- Orientation + layout logic ---
    switch Orientation
        case "horizontal"
            Legend_Handle.NumColumns = NumColumns;
        case "vertical"
            Legend_Handle.NumColumns = 1;
            if NumRows < numel(Legend_Entries)
                Legend_Handle.NumColumns = ceil(numel(Legend_Entries)/NumRows);
            end
        otherwise
            Legend_Handle.NumColumns = 1;
    end

    % --- Auto location selection using data density ---
    if AutoLocation
        Candidate_Positions = ["northeast","northwest","southeast","southwest","north","south","east","west"];
        MinOverlap = inf;
        BestPos = "best";
        for Pos = Candidate_Positions
            Legend_Handle.Location = Pos;
            drawnow
            Legend_Pos = Legend_Handle.Position;
            DataDensity = estimate_data_density(Ax, Legend_Pos, Padding);
            if DataDensity < MinOverlap
                MinOverlap = DataDensity;
                BestPos = Pos;
            end
        end
        Legend_Handle.Location = BestPos;
    else
        Legend_Handle.Location = LocationOverride;
    end

    if ~Hold_State
        hold(Ax, "off");
    end
end