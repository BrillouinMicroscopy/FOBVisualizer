function callbacks = Help(model, view)
%% DATA Controller

    %% general panel
    set(view.menubar.helpAbout, 'Callback', {@openAbout, model, view});

    callbacks = struct( ...
    );
end

function openAbout(~, ~, model, view)
    if isfield(view.help, 'parent') && ishandle(view.help.parent)
        return;
    else
        width = 470;
        height = 140;
        figPos = view.figure.Position;
        x = figPos(1) + (figPos(3) - width)/2;
        y = figPos(2) + (figPos(4) - height)/2;
        parent = figure('Position',[x,y,width,height],'Name','About');
        % hide the menubar and prevent resizing
        set(parent, 'menubar', 'none', 'Resize','off');
    end
    
    view.help = FV_View.HelpAbout(parent, model);
end