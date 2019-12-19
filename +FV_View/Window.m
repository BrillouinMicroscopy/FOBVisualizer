function Window(model, view)
%% TABS View

    % build the GUI
    initGUI(model, view);
end

function initGUI(model, view)
    f = figure('Visible','off','Position',[-1000,200,1400,800]);
    % hide the menubar and prevent resizing
    set(f, 'menubar', 'none', 'Resize', 'off');
    
    % set menubar
    menubar.file = uimenu(f,'Label','&File');
    menubar.fileOpen   = uimenu(menubar.file,'Label','Open','Accelerator','O');
    menubar.fileClose  = uimenu(menubar.file,'Label','Close','Accelerator','W');                 
    menubar.fileSave   = uimenu(menubar.file,'Label','Save','Accelerator','S');
    
    menubar.edit = uimenu(f,'Label','&Edit');
    menubar.openAlignment = uimenu(menubar.edit,'Label','Align','Accelerator','A');
    
    menubar.help = uimenu(f,'Label','&Help');
    menubar.helpAbout  = uimenu(menubar.help,'Label','About','Accelerator','H');
    
    view.data.parent = f;
    view.ODT.parent = f;
    view.Fluorescence.parent = f;
    view.Brillouin.parent = f;
    view.Modulus.parent = f;
    
    FV_View.Data(view, model);
    FV_View.ODT(view, model);
    FV_View.Fluorescence(view, model);
    FV_View.Brillouin(view, model);
    FV_View.Modulus(view, model);
                 
    % Assign the name to appear in the window title.
    version = sprintf('%d.%d.%d', model.programVersion.major, model.programVersion.minor, model.programVersion.patch);
    if ~strcmp('', model.programVersion.preRelease)
        version = [version '-' model.programVersion.preRelease];
    end
    f.Name = sprintf('FOB Visualizer v%s', version);

    % Move the window to the center of the screen.
    movegui(f,'center')

    % Make the window visible.
    f.Visible = 'on';
    
    % return a structure of GUI handles
    view.figure = f;
    view.menubar = menubar;
end