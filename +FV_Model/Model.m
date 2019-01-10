classdef Model < handle
%% MODEL

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        file = [];          % handle to the H5BM file
        filename = [];      % name of the H5BM file
        filepath = [];      % path to the H5BM file
        controllers;        % handle to all controllers
        pp = [];            % path to the program
        log;                % logging object
    end
    properties (Constant)
        programVersion = getProgramVersion();
    end

    methods
        function obj = Model()
        end
        %% Function to reset the model
        function reset(obj)
            obj.file = [];
        end
    end
end

function programVersion = getProgramVersion()
    %% check if git commit can be found
    commit = '';
    cleanRepo = 'False';
    fp = mfilename('fullpath');
    [path,~,~] = fileparts(fp);
    try
        [status,com] = system(['git -C "' path '" log -n 1 --format=format:%H']);
        if ~status
            commit = com;
        end
        [status,clean] = system(['git -C "' path '" ls-files --exclude-standard -d -m -o -k']);
        if ~status
            cleanRepo = isempty(clean);
        end
    catch
        % program folder does not contain git folder
    end

    programVersion = struct( ...
        'major', 0, ...
        'minor', 0, ...
        'patch', 1, ...
        'preRelease', 'alpha', ...
        'commit', commit, ...
        'cleanRepo', cleanRepo, ...
        'website', 'https://github.com/BrillouinMicroscopy/FOBVisualizer', ...
        'author', 'Raimund Schlüßler', ...
        'email', 'raimund.schluessler@tu-dresden.de', ...
        'link', ['https://github.com/BrillouinMicroscopy/FOBVisualizer/commit/' commit] ...
    );     % version of the evaluation program
end