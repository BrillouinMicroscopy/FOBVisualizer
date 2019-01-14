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

    file_information = uipanel('Parent', parent, 'Title', 'File information', 'FontSize', 11,...
                 'Position', [.01 .93 .98 .065]);
    
    uicontrol('Parent', file_information, 'Style','text','String','Filename:', 'Units', 'normalized',...
               'Position',[0.01,0.3,0.05,0.6], 'FontSize', 11, 'HorizontalAlignment', 'left');
    filename = uicontrol('Parent', file_information, 'Style','text', 'Units', 'normalized',...
               'Position',[0.065,0.3,0.6,0.6], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', '');
    
    uicontrol('Parent', file_information, 'Style','text','String','Date:', 'Units', 'normalized',...
               'Position',[0.65,0.3,0.03,0.6], 'FontSize', 11, 'HorizontalAlignment', 'left');
    date = uicontrol('Parent', file_information, 'Style','text', 'Units', 'normalized',...
               'Position',[0.685,0.3,0.2,0.6], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', '');
    
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
        set(handles.filename, 'String', [model.filepath model.filename]);
        set(handles.date, 'String', model.file.date);
    else
        set(handles.filename, 'String', '');
        set(handles.date, 'String', '');
    end
end
