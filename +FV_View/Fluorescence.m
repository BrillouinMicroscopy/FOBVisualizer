function Fluorescence(view, model)
%% FLUORESCENCE View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'Fluorescence', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
    
    addlistener(model, 'Brillouin', 'PostSet', ...
        @(o,e) onBrillouinChange(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.Fluorescence.parent;
    
    uicontrol('Parent', parent, 'Style','text','String','Fluorescence repetition:', 'Units', 'normalized',...
               'Position',[0.34,0.885,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetition = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized',...
               'Position',[0.47,0.91,0.05,0.005], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', {''});
    uicontrol('Parent', parent, 'Style','text','String','of', 'Units', 'normalized',...
               'Position',[0.53,0.885,0.02,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetitionCount = uicontrol('Parent', parent, 'Style','text','String','0', 'Units', 'normalized',...
               'Position',[0.55,0.885,0.02,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    uicontrol('Parent', parent, 'Style','text','String','Channel:', 'Units', 'normalized',...
               'Position',[0.34,0.85,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    channels = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized',...
               'Position',[0.47,0.875,0.1,0.005], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', {''}, 'Value', 1);
    
    uicontrol('Parent', parent, 'Style','text','String','Date:', 'Units', 'normalized',...
               'Position',[0.34,0.815,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    date = uicontrol('Parent', parent, 'Style','text', 'Units', 'normalized',...
               'Position',[0.47,0.815,0.19,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', '');
    
    axesImage = axes('Parent', parent, 'Position', [0.36 .46 .26 .34]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
             
    %% Return handles
    view.Fluorescence = struct(...
        'parent', parent, ...
        'repetition', repetition, ...
        'repetitionCount', repetitionCount, ...
        'channels', channels, ...
        'plot', NaN, ...
        'positionPlot', NaN, ...
        'date', date, ...
        'axesImage', axesImage ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileChange(view, model)
end

function onFileChange(view, model)
    Fluorescence = model.Fluorescence;
    handles = view.Fluorescence;
    reps = Fluorescence.repetitions;
    if (isempty(reps))
        set(handles.repetitionCount, 'String', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'String', length(reps));
    end
    set(handles.repetition, 'String', reps);
    set(handles.repetition, 'Value', Fluorescence.repetition+1);

    if ~isempty(Fluorescence.repetitions)
        try
            imageNames = model.file.readPayloadData('Fluorescence', Fluorescence.repetition, 'memberNames');
            if (Fluorescence.channel >= length(imageNames))
                Fluorescence.channel = 0;
            end
            set(handles.channels, 'String', imageNames);
            set(handles.channels, 'Value', Fluorescence.channel+1);
            
            ax = handles.axesImage;
            type = model.file.readPayloadData('Fluorescence', Fluorescence.repetition, 'channel', Fluorescence.channel);
            
            image = model.file.readPayloadData('Fluorescence', Fluorescence.repetition, 'data', Fluorescence.channel);
            image = medfilt1(image, 3);
            date = model.file.readPayloadData('Fluorescence', Fluorescence.repetition, 'date', Fluorescence.channel);
            set(handles.date, 'String', date);
            
            x = 4.8*(1:size(image, 1))/57;
            x = x - nanmean(x(:));
            y = 4.8*(1:size(image, 2))/57;
            y = y - nanmean(y(:));
    
            if ishandle(view.Fluorescence.plot)
                delete(view.Fluorescence.plot)
            end
            view.Fluorescence.plot = imagesc(ax, x, y, image);
            shading(ax, 'flat');
            axis(ax, 'equal');
            xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
            caxis(ax, [min(image(:)), max(image(:))]);
            colorbar(ax);
            switch (type)
                case 'Brightfield'
                    colormap(ax, 'gray')
                case 'Green'
                    greenColor=zeros(64,3);
                    greenColor(:,2)=linspace(0,1,64);
                    colormap(ax, greenColor);
                case 'Red'
                    redColor=zeros(64,3);
                    redColor(:,1)=linspace(0,1,64);
                    colormap(ax, redColor);
                case 'Blue'
                    blueColor=zeros(64,3);
                    blueColor(:,3)=linspace(0,1,64);
                    colormap(ax, blueColor);
            end
%             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
            set(ax, 'yDir', 'normal');
            onFOVChange(view, model);
            onBrillouinChange(view, model);
        catch
            if ishandle(view.Fluorescence.plot)
                delete(view.Fluorescence.plot)
            end
            set(handles.channels, 'String', {''});
            set(handles.channels, 'Value', 1);
            set(handles.date, 'String', '');
        end
    else
        if ishandle(view.Fluorescence.plot)
            delete(view.Fluorescence.plot)
        end
        set(handles.channels, 'String', {''});
        set(handles.channels, 'Value', 1);
        set(handles.date, 'String', '');
    end
end

function onFOVChange(view, model)
    ax = view.Fluorescence.axesImage;
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end

function onBrillouinChange(view, model)
    if ~isempty(model.Fluorescence.repetitions)
        ax = view.Fluorescence.axesImage;
        hold(ax, 'on');
        if ishandle(view.Fluorescence.positionPlot)
            delete(view.Fluorescence.positionPlot)
        end
        if length(model.Brillouin.position.x) == 1
            view.Fluorescence.positionPlot = plot(ax, model.Brillouin.position.x, model.Brillouin.position.y, 'color', 'red', 'linewidth', 1.5, 'marker', 'o');
        else
            view.Fluorescence.positionPlot = plot(ax, model.Brillouin.position.x, model.Brillouin.position.y, 'color', 'red', 'linewidth', 1.5);
        end
    end
end
