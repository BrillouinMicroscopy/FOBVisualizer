function Data(view, model)
%% DATA View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'file', 'PostSet', ...
        @(o,e) onFileLoad(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.data.parent;

    file_information = uipanel(parent, 'Title', 'File information', ...
        'Position', [10 745 1380 50]);
    
    uilabel(file_information, 'Text', 'Filename:', ...
        'Position',[10 5 60 20], 'HorizontalAlignment', 'left');
    filename = uilabel(file_information, 'Text', '', ...
        'Position',[75 5 725 20], 'HorizontalAlignment', 'left');
    
    uilabel(file_information, 'Text', 'Date:', ...
        'Position', [910 5 50 20], 'HorizontalAlignment', 'left');
    date = uilabel(file_information, 'Text', '', ...
        'Position', [965 5 425 20], 'HorizontalAlignment', 'left');
    
    %% Return handles
    view.data = struct(...
        'parent', parent, ...
        'filename', filename, ...
        'date', date, ...
        'file_information', file_information ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileLoad(view, model)
end

function onFileLoad(view, model)
    handles = view.data;
    
    if isa(model.file,'FV_Utils.HDF5Storage.h5bm') && isvalid(model.file)
        set(handles.filename, 'Text', [model.filepath model.filename]);
        set(handles.date, 'Text', model.file.date);
    else
        set(handles.filename, 'Text', '');
        set(handles.date, 'Text', '');
    end
end
