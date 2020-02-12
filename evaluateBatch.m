% script for automatically evaluating FOB data
% copy this file to the folder with the data you want to evaluate and
% adjust the parameters below if necessary

%% path to the files
filelist = dir('**/*.h5');

%% parameter structure
parameters = struct( ...
    'parameters', struct( ...
        'magnification', 57, ...        % [1]   microscope magnification
        'pixelSize', 4.8e-6 ...         % [µm]  camera pixel size
    ), ...
    'Alignment', struct( ...            % parameters for the extraction
        'do', true ...                  % execute alignment?
    ), ...
    'density', struct( ...              % parameters for the calibration
        'do', true, ...                 % execute density calculation?
        'n0', 1.337, ...                % [1]    refractive index of PBS
        'alpha', 0.19, ...              % [ml/g] refraction increment
        'rho0', 1, ...                  % [g/ml] density of PBS
        'useDryDensity', true, ...      % [boolean] whether the absolute density of the dry mass should be considered
        'rho_dry', 1.35 ...             % [g/ml] absolute density of the dry fraction, 1/rho_dry = \bar{\nu}_\mathrm{dry} in
    ) ...
);

FOBVisualizer_Auto(filelist, parameters);
