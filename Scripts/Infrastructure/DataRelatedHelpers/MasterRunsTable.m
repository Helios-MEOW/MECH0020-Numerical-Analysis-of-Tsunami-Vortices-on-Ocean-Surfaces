classdef MasterRunsTable
    % MasterRunsTable - Append-safe master runs table across all methods/modes
    %
    % Purpose:
    %   Single CSV tracking all runs (Results/Runs_Table.csv)
    %   Append-safe with schema evolution support
    %   Optional Excel export with conditional formatting
    %
    % Usage:
    %   MasterRunsTable.append_run(run_id, Run_Config, Parameters, Results);
    %   MasterRunsTable.export_to_excel();  % Optional
    
    methods (Static)
        function append_run(run_id, Run_Config, Parameters, Results)
            % Append new run to master table
            
            % Get master table path
            table_path = PathBuilder.get_master_table_path();
            
            % Ensure Results directory exists
            results_dir = fileparts(table_path);
            if ~exist(results_dir, 'dir')
                mkdir(results_dir);
            end
            
            % Create row for this run
            row = MasterRunsTable.create_row(run_id, Run_Config, Parameters, Results);
            
            % Load existing table or create new
            if exist(table_path, 'file')
                existing = readtable(table_path, 'Delimiter', ',');
                % Schema evolution: add missing columns
                existing_fields = existing.Properties.VariableNames;
                row_fields = row.Properties.VariableNames;
                
                % Add new fields to existing table
                for i = 1:length(row_fields)
                    if ~ismember(row_fields{i}, existing_fields)
                        existing.(row_fields{i}) = repmat({''}, height(existing), 1);
                    end
                end
                
                % Add missing fields to new row
                for i = 1:length(existing_fields)
                    if ~ismember(existing_fields{i}, row_fields)
                        row.(existing_fields{i}) = {''};
                    end
                end
                
                % Append row
                master = [existing; row];
            else
                master = row;
            end
            
            % Write to CSV
            writetable(master, table_path, 'Delimiter', ',');
        end
        
        function export_to_excel()
            % Export master table to Excel with formatting (if available)
            
            table_path = PathBuilder.get_master_table_path();
            if ~exist(table_path, 'file')
                warning('MasterRunsTable:NoTable', 'Master table does not exist yet');
                return;
            end
            
            excel_path = strrep(table_path, '.csv', '.xlsx');
            
            try
                % Read CSV
                master = readtable(table_path, 'Delimiter', ',');
                
                % Write to Excel
                writetable(master, excel_path, 'Sheet', 'Runs');
                
                % Attempt conditional formatting (platform-dependent)
                try
                    MasterRunsTable.apply_excel_formatting(excel_path);
                catch ME
                    % Formatting not available on this platform
                    warning('MasterRunsTable:FormattingFailed', ...
                        'Excel formatting not available: %s', ME.message);
                end
                
            catch ME
                warning('MasterRunsTable:ExcelExportFailed', ...
                    'Could not export to Excel: %s', ME.message);
            end
        end
        
        function table_data = query(filters)
            % Query master table with filters
            % filters: struct with field-value pairs
            %
            % Example:
            %   data = MasterRunsTable.query(struct('method', 'FD', 'mode', 'Evolution'));
            
            table_path = PathBuilder.get_master_table_path();
            if ~exist(table_path, 'file')
                table_data = table();
                return;
            end
            
            % Read table
            table_data = readtable(table_path, 'Delimiter', ',');
            
            % Apply filters
            if ~isempty(filters)
                fields = fieldnames(filters);
                for i = 1:length(fields)
                    if ismember(fields{i}, table_data.Properties.VariableNames)
                        mask = strcmp(table_data.(fields{i}), filters.(fields{i}));
                        table_data = table_data(mask, :);
                    end
                end
            end
        end
    end
    
    methods (Static, Access = private)
        function row = create_row(run_id, Run_Config, Parameters, Results)
            % Create table row from run data
            
            % Core identifiers
            row_data = struct();
            row_data.run_id = {run_id};
            row_data.timestamp = {char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'))};
            row_data.method = {Run_Config.method};
            row_data.mode = {Run_Config.mode};
            
            % Configuration
            if isfield(Run_Config, 'ic_type')
                row_data.ic_type = {Run_Config.ic_type};
            else
                row_data.ic_type = {''};
            end
            
            % Parameters (common ones)
            row_data.Nx = MasterRunsTable.safe_extract(Parameters, 'Nx', NaN);
            row_data.Ny = MasterRunsTable.safe_extract(Parameters, 'Ny', NaN);
            row_data.dt = MasterRunsTable.safe_extract(Parameters, 'dt', NaN);
            row_data.Tfinal = MasterRunsTable.safe_extract(Parameters, 'Tfinal', NaN);
            row_data.nu = MasterRunsTable.safe_extract(Parameters, 'nu', NaN);
            row_data.Lx = MasterRunsTable.safe_extract(Parameters, 'Lx', NaN);
            row_data.Ly = MasterRunsTable.safe_extract(Parameters, 'Ly', NaN);
            
            % Results (common metrics)
            row_data.wall_time_s = MasterRunsTable.safe_extract(Results, 'wall_time', NaN);
            row_data.final_time = MasterRunsTable.safe_extract(Results, 'final_time', NaN);
            row_data.total_steps = MasterRunsTable.safe_extract(Results, 'total_steps', NaN);
            row_data.max_omega = MasterRunsTable.safe_extract(Results, 'max_omega', NaN);
            row_data.final_energy = MasterRunsTable.safe_extract(Results, 'final_energy', NaN);
            row_data.final_enstrophy = MasterRunsTable.safe_extract(Results, 'final_enstrophy', NaN);
            
            % Convert to table
            row = struct2table(row_data);
        end
        
        function val = safe_extract(s, field, default)
            % Safely extract field or return default
            if isfield(s, field)
                val = s.(field);
            else
                val = default;
            end
        end
        
        function apply_excel_formatting(excel_path)
            % Apply conditional formatting to Excel (Windows + Excel COM only)
            
            % This requires Excel COM automation (Windows only)
            % Gracefully degrade if not available
            
            if ~ispc
                return;  % Not Windows
            end
            
            try
                % Create Excel COM object
                Excel = actxserver('Excel.Application');
                Excel.Visible = false;
                Workbook = Excel.Workbooks.Open(excel_path);
                Sheet = Workbook.Sheets.Item('Runs');
                
                % Apply conditional formatting to wall_time column
                % (Color scale: green=fast, red=slow)
                try
                    wall_time_col = find(strcmp(Sheet.Range('A1:Z1').Value, 'wall_time_s'));
                    if ~isempty(wall_time_col)
                        last_row = Sheet.UsedRange.Rows.Count;
                        range = Sheet.Range(sprintf('%s2:%s%d', ...
                            char('A' + wall_time_col - 1), ...
                            char('A' + wall_time_col - 1), last_row));
                        range.FormatConditions.AddColorScale(3);
                    end
                catch
                    % Conditional formatting failed
                end
                
                % Save and close
                Workbook.Save();
                Workbook.Close();
                Excel.Quit();
                delete(Excel);
                
            catch ME
                % COM automation failed - Excel not available or error
                % This is expected on non-Windows or without Excel installed
            end
        end
    end
end
