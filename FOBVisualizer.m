function varargout = FOBVisualizer
%% MAINCONTROLLER  MainController

    % controller knows about model and view
    clear model;
    model = FV_Model.Model();      % model is independent
    
    includePath(model);
    
    clear view;
    view = FV_View.View();
    
    FV_View.Window(model, view);    % view has a reference of the model
    
    controllers = controller(model, view);
    model.controllers = controllers;
    
    % add logging class
    model.log = FV_Utils.Logging.Logging(model.pp, 'log.log');
    model.log.write('');
    model.log.write('#####################################################');
    model.log.log('V/FOBVisualizer: Opened program.');
    model.log.write('=====================================================');
    
    set(view.figure, 'CloseRequestFcn', {@closeGUI, model, view, controllers});
    
    controllers.closeGUI = @() closeGUI(0, 0, model, view, controllers);
    
    if nargout > 0
        varargout{1} = controllers;
    end
    if nargout > 1
        varargout{2} = model;
    end
    if nargout > 2
        varargout{3} = view;
    end
end

function closeGUI(~, ~, model, view, controllers)
    controllers.data.closeFile();
    model.log.write('=====================================================');
    model.log.log('V/FOBVisualizer: Closed program.');
    delete(view.figure);
end

function controllers = controller(model, view)
    data = FV_Controller.Data(model, view);
    Brillouin = FV_Controller.Brillouin(model, view);
    fluorescence = FV_Controller.Fluorescence(model, view);
    ODT = FV_Controller.ODT(model, view);
    help = FV_Controller.Help(model, view);
    controllers = struct( ...
        'data', data, ...
        'Brillouin', Brillouin, ...
        'fluorescence', fluorescence, ...
        'ODT', ODT, ...
        'help', help ...
    );
end

function includePath(model)
    fp = mfilename('fullpath');
    [model.pp,~,~] = fileparts(fp);
    addpath(model.pp);
end