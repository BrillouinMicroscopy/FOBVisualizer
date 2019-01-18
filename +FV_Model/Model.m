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
        parameters;         % general parameters
        Brillouin;          % parameters of the Brillouin measurement
        Fluorescence;       % parameters of the Fluorescence measurement
        ODT;                % parameters of the ODT measurement
    end
    properties (Constant)
        programVersion = getProgramVersion();
        % Saved to evaluated data file
        defaultBrillouin = struct( ...
            'repetitions', {{}}, ...
            'repetition', 0, ...
            'dimension', NaN, ...
            'position', struct( ...
                'x', [], ...
                'y', [], ...
                'z', [] ...
            ) ...
        );
        defaultFluorescence = struct( ...
            'repetitions', {{}}, ...
            'repetition', 0, ...
            'channel', 0, ...
            'indicate', true ...
        );
        defaultODT = struct( ...
            'repetitions', {{}}, ...
            'repetition', 0, ...
            'indicate', true ...
        );
        defaultParameters = struct( ...
            'magnification', 57, ...    % [1]   microscope magnification
            'pixelSize', 4.8e-6, ...    % [�m]  camera pixel size
            'xlim', [NaN NaN], ...
            'ylim', [NaN NaN] ...
        );
    end

    methods
        function obj = Model()
            obj.Brillouin = obj.defaultBrillouin();
            obj.Fluorescence = obj.defaultFluorescence();
            obj.ODT = obj.defaultODT();
            obj.parameters = obj.defaultParameters();
        end
        %% Function to reset the model
        function reset(obj)
            obj.file = [];
            obj.Brillouin = obj.defaultBrillouin();
            obj.Fluorescence = obj.defaultFluorescence();
            obj.ODT = obj.defaultODT();
            obj.parameters = obj.defaultParameters();
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
        'author', 'Raimund Schl��ler', ...
        'email', 'raimund.schluessler@tu-dresden.de', ...
        'link', ['https://github.com/BrillouinMicroscopy/FOBVisualizer/commit/' commit] ...
    );     % version of the evaluation program
end