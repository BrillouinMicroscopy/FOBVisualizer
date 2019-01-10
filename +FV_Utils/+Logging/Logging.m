classdef Logging < handle
    properties (Access = private)
        basePath;
        logPath;
        logHandle;
    end
    
	methods
        %% Constructor
        function obj = Logging(basePath, logName)
            obj.basePath = basePath;
            obj.logPath = [basePath filesep logName];
            obj.logHandle = fopen(obj.logPath, 'a');
        end
        
        %% Destructor
        function delete(obj)
            try
                fclose(obj.logHandle);
            catch
            end
        end
        
        %% Add new line to log
        function write(obj, data)
            try
                fprintf(obj.logHandle, '%s', data);
                fprintf(obj.logHandle, '\r\n');
            catch
                obj.logHandle = fopen(obj.logPath, 'a');
                fprintf(obj.logHandle, '%s', data);
                fprintf(obj.logHandle, '\r\n');
            end
        end
        
        %% Add new line to log with enhanced details
        function log(obj, varargin)
            stack = dbstack('-completenames', 1);
            % add datetime string
            datum = datetime('now', 'format', 'uuuu-MM-dd''T''HH:mm:ss.SSSXXX', 'TimeZone', 'local');
            datum = char(datum);
            if size(varargin,2) > 1
                file = strrep(strrep(stack(1).file, obj.basePath, ''), '\', '/');
                str = [char(datum), ': ', varargin{1}, file, '(' num2str(stack(1).line) '): ' varargin{2}];
            else
                str = [char(datum), ': ', varargin{1}];
            end
            fprintf(obj.logHandle, '%s', str);
            fprintf(obj.logHandle, '\r\n');
        end
    end
    methods (Static)
    end
end