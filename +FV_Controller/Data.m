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
        model.Brillouin.repetitions = model.file.getRepetitions('Brillouin');
        
        % Fluorescence
        model.Fluorescence.repetitions = model.file.getRepetitions('Fluorescence');
        
        % ODT
        model.ODT.repetitions = model.file.getRepetitions('ODT');
        
        model.controllers.Brillouin.loadRepetition();
        model.controllers.ODT.loadRepetition();
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

function selectSaveData(~, ~, model)
end