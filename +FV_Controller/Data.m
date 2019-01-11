function callbacks = Data(model, view)
%% DATA Controller

    %% general panel
    set(view.menubar.fileOpen, 'Callback', {@selectLoadData, model});
    set(view.menubar.fileClose, 'Callback', {@closeFile, model});
    set(view.menubar.fileSave, 'Callback', {@selectSaveData, model});

    callbacks = struct( ...
        'open', @(filePath)openFile(model, filePath), ...
        'closeFile', @()closeFile('', '', model) ...
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
    model.filepath = [PathName '\'];
    if ~isequal(PathName,0) && exist(filePath, 'file')
        
        %% Store file handle
        model.file = FV_Utils.HDF5Storage.h5bmread(filePath);
        
        model.filename = [name extension];
        
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
        
        %% Open the raw data file
        file = H5F.open(filePath);
        
        %% Find all measurements for Brillouin, Fluorescence and ODT
        % Brillouin
        Brillouin = model.Brillouin;
        gid = H5G.open(file,'/Brillouin');
        Brillouin.repetitions = {};
        [~, ~, Brillouin] = H5L.iterate(gid, 'H5_INDEX_NAME' , 'H5_ITER_INC', 0, @addBrillouinRepetition, Brillouin);
        H5G.close(gid);
        model.Brillouin = Brillouin;
        
        % Fluorescence
        Fluorescence = model.Fluorescence;
        gid = H5G.open(file,'/Fluorescence');
        Fluorescence.repetitions = {};
        [~, ~, Fluorescence] = H5L.iterate(gid, 'H5_INDEX_NAME' , 'H5_ITER_INC', 0, @addFluorescenceRepetition, Fluorescence);
        H5G.close(gid);
        model.Fluorescence = Fluorescence;
        
        % ODT
        ODT = model.ODT;
        gid = H5G.open(file,'/ODT');
        ODT.repetitions = {};
        [~, ~, ODT] = H5L.iterate(gid, 'H5_INDEX_NAME' , 'H5_ITER_INC', 0, @addODTRepetition, ODT);
        H5G.close(gid);
        model.ODT = ODT;
        
        H5F.close(file);
    end
end
        
function [status, Brillouin] = addBrillouinRepetition(~, name, Brillouin)
    %% Add group to array of repetitions
    Brillouin.repetitions{length(Brillouin.repetitions)+1} = name;
    status = 0;
end
        
function [status, Fluorescence] = addFluorescenceRepetition(~, name, Fluorescence)
    %% Add group to array of repetitions
    Fluorescence.repetitions{length(Fluorescence.repetitions)+1} = name;
    status = 0;
end
        
function [status, ODT] = addODTRepetition(~, name, ODT)
    %% Add group to array of repetitions
    ODT.repetitions{length(ODT.repetitions)+1} = name;
    status = 0;
end

function closeFile(~, ~, model)
    if ~isempty(model.filename)
        model.log.log(['I/File: Closed file "' model.filepath model.filename '"']);
        model.log.write('');
    end
    model.reset();
end

function selectSaveData(~, ~, model)
end