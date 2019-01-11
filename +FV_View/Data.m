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
    
    %% Return handles
    view.data = struct(...
        'parent', parent, ...
        'file_information', file_information ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileLoad(view, model)
end

function onFileLoad(view, model)
    handles = view.data;
end
