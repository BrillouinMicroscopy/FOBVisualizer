function callbacks = Data(model, view)
%% DATA Controller

    %% general panel
    set(view.menubar.fileOpen, 'Callback', {@selectLoadData, model});
    set(view.menubar.fileClose, 'Callback', {@closeFile, model});
    set(view.menubar.fileSave, 'Callback', {@selectSaveData, model});

    set(view.menubar.openAlignment, 'Callback', {@openAlignment, view, model});

    callbacks = struct( ...
        'open', @(filePath)openFile(model, filePath), ...
        'openFile', @(filePath)openFile(model, filePath), ...
        'openAlignment', @()openAlignment('', '', view, model), ...
        'save', @()selectSaveData('', '', model), ...
        'closeFile', @()closeFile('', '', model), ...
        'setParameters', @(parameters)setParameters(model, parameters), ...
        'loadAlignmentData', @()loadAlignmentData(model) ...
    );
end

function selectLoadData(~, ~, model)
    [FileName,PathName,~] = uigetfile('*.h5', 'Select the raw data file to visualize.');
    filePath = [PathName FileName];
    openFile(model, filePath);
end

function openFile(model, filePath)
    if isempty(filePath) || ~sum(filePath)
        return
    end
    model.reset;
    % Load the h5bm data file
    model.log.log(['I/File: Opened file "' filePath '"']);
    if isempty(filePath) || ~sum(filePath)
        return
    end
    [PathName, name, extension] = fileparts(filePath);
    model.filepath = [PathName filesep];
    if ~isequal(PathName,0) && exist(filePath, 'file')
        
        %% Store file handle
        model.filename = [name extension];
        
        model.file = FV_Utils.HDF5Storage.h5bmread(filePath);
        
        %% Try to load either ODT or Fluorescence file to figure out the resolution
        parameters = model.parameters;
        try
            ODT = model.file.readPayloadData('ODT', 0, 'data', 0);
            x = 1e6*model.parameters.pixelSize*(1:size(ODT, 1))/model.parameters.magnification;
            x = x - nanmean(x(:));
            parameters.xlim = [min(x(:)), max(x(:))];
            y = 1e6*model.parameters.pixelSize*(1:size(ODT, 2))/model.parameters.magnification;
            y = y - nanmean(y(:));
            parameters.ylim = [min(y(:)), max(y(:))];
        catch
        end
        model.parameters = parameters;
        
        %% Find all measurements for Brillouin, Fluorescence and ODT
        % Brillouin
        Brillouin = model.Brillouin;
        Brillouin.repetitions = model.file.getRepetitions('Brillouin');
        Brillouin.repetition.index = 1;
        Brillouin.repetition.name = Brillouin.repetitions{1};
        model.Brillouin = Brillouin;
        
        % Fluorescence
        Fluorescence = model.Fluorescence;
        Fluorescence.repetitions = model.file.getRepetitions('Fluorescence');
        Fluorescence.repetition.index = 1;
        Fluorescence.repetition.name = Fluorescence.repetitions{1};
        model.Fluorescence = Fluorescence;
        
        % ODT
        ODT = model.ODT;
        ODT.repetitions = model.file.getRepetitions('ODT');
        ODT.repetition.index = 1;
        ODT.repetition.name = ODT.repetitions{1};
        model.ODT = ODT;
        
        model.controllers.Brillouin.loadRepetition();
        model.controllers.ODT.loadRepetition();
        loadAlignmentData(model);
    end
end

%%
function [status, memberNames] = addRepetition(~, memberName, memberNames)
    %% Add group to array of repetitions
    memberNames{length(memberNames)+1} = memberName;
    status = 0;
end

function closeFile(~, ~, model)
    if ~isempty(model.filename)
        model.log.log(['I/File: Closed file "' model.filepath model.filename '"']);
        model.log.write('');
    end
    model.reset();
end

function setParameters(model, parameters)
    f = fields(parameters);
    for jj = 1:length(f)
        model.(f{jj}) = copyFields(model.(f{jj}), parameters.(f{jj}));
    end
    
    %% recursively copy parameters into model
    function target = copyFields(target, source)
        for fn = fieldnames(source).'
            if isstruct(source.(fn{1}))
                target.(fn{1}) = copyFields(target.(fn{1}), source.(fn{1}));
            else
                target.(fn{1}) = source.(fn{1});
            end
        end
    end
end

function selectSaveData(~, ~, model)
    filepath = constructAlignmentFilepath(model);
    
    Alignment = model.Alignment;
    modulus = model.modulus;
    density = model.density;
    programVersion = model.programVersion;
    save(filepath, 'Alignment', 'modulus', 'programVersion', 'density');
end

function loadAlignmentData(model)
    filepath = constructAlignmentFilepath(model);
    
    if exist(filepath, 'file')
        data = load(filepath, 'Alignment', 'modulus', 'density');
        Alignment = data.Alignment;
        modulus = data.modulus;
        %% Try to load density data
        try
            density = data.density;
        % Migrate if that fails
        catch
            density = modulus;
            if isfield(density, 'M')
                modulus = struct( ...
                    'M', density.M, ...
                    'M_woRI', density.M_woRI ...
                );
                density = rmfield(density, 'M');
                density = rmfield(density, 'M_woRI');
            end
        end
    else
        Alignment = model.defaultAlignment;
        modulus = model.defaultModulus;
        density = model.defaultDensity;
    end
    if ~isfield(Alignment, 'z0')
        Alignment.z0 = model.defaultAlignment.z0;
    end
    if ~isfield(density, 'rho_dry')
        density.rho_dry = model.defaultDensity.rho_dry;
    end
    if ~isfield(density, 'useDryDensity')
        density.useDryDensity = model.defaultDensity.useDryDensity;
    end
    if ~isfield(density, 'masks')
        density.masks = struct();
    end
    model.modulus = modulus;
    model.density = density;
    model.controllers.Brillouin.extractAlignment(Alignment);
    model.controllers.density.calculateDensity();
end

function filepath = constructAlignmentFilepath(model)
    Brillouin = model.Brillouin;
    ODT = model.ODT;
    [~, name, ~] = fileparts(model.filename);
    if length(Brillouin.repetitions) > 1
        name = [name '_BMrep' num2str(Brillouin.repetition.name)];
    end
    if length(ODT.repetitions) > 1
        name = [name '_ODTrep' num2str(ODT.repetition.name)];
    end
    filepath = [model.filepath '..' filesep 'EvalData' filesep name '_modulus.mat'];
end

function openAlignment(~, ~, view, model)    
    if isfield(view.Alignment, 'parent') && ishandle(view.Alignment.parent)
        figure(view.Alignment.parent);
        return;
    else
        % open it centered over main figure
        pos = view.figure.Position;
        parent = figure('Position', [pos(1) + pos(3)/2 - 500, pos(2) + pos(4)/2 - 325, 1000, 650]);
        % hide the menubar and prevent resizing
        set(parent, 'menubar', 'none', 'Resize','off', 'units', 'pixels');
    end

    view.Alignment = FV_View.Alignment(parent, model);

    model.controllers.Alignment = FV_Controller.Alignment(model, view);
end