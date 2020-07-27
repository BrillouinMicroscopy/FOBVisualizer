function Fluorescence(view, model)
%% FLUORESCENCE View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'Fluorescence', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'Alignment', 'PostSet', ...
        @(o,e) onAlignment(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.Fluorescence.parent;
    
    uilabel(parent, 'Text', 'Fluorescence repetition:', 'Position', [470 710 130 20], ...
        'HorizontalAlignment', 'left');
    repetition = uidropdown(parent, 'Position', [600 710 100 20], ...
        'Items', {''});
    uilabel(parent, 'Text', 'of', 'Position', [720 710 30 20], ...
        'HorizontalAlignment', 'left');
    repetitionCount = uilabel(parent, 'Text', '0', 'Position', [750 710 30 20], ...
        'HorizontalAlignment', 'left');
    
    uilabel(parent, 'Text', 'Channel:', 'Position', [470 690 100 20], ...
        'HorizontalAlignment', 'left');
    channels = uidropdown(parent, 'Position', [600 690 200 18], ...
        'Items', {''});
    
    uilabel(parent, 'Text', 'Date:', 'Position', [470 670 100 20], ...
        'HorizontalAlignment', 'left');
    date = uilabel(parent, 'Text', '', 'Position', [600 670 300 20], ...
        'HorizontalAlignment', 'left');
    
    axesImage = uiaxes(parent, 'Position', [500 350 390 300]);
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
        set(handles.repetitionCount, 'Text', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'Text', num2str(length(reps)));
    end
    set(handles.repetition, 'Items', reps);
    set(handles.repetition, 'Value', Fluorescence.repetition.name);

    if ~isempty(Fluorescence.repetitions)
        try
            channelNames = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'memberNames');
            if (Fluorescence.channel > length(channelNames))
                Fluorescence.channel = 1;
            end
            
            channelName = channelNames{Fluorescence.channel};
            set(handles.channels, 'Items', channelNames);
            set(handles.channels, 'Value', channelName);
            
            ax = handles.axesImage;
            type = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'channel', channelName);
            
            image = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'data', channelName);
            image = medfilt1(image, 3);
            date = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'date', channelName);
            set(handles.date, 'Text', date);
            
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
            xlabel(ax, '{\it x} [µm]', 'interpreter', 'tex');
            ylabel(ax, '{\it y} [µm]', 'interpreter', 'tex');
            caxis(ax, [min(image(:)), max(image(:))]);
            cb = colorbar(ax);
            ylabel(cb, '{\it I} [a.u.]', 'interpreter', 'tex', 'FontSize', 10);
            type = lower(type);
            switch (type)
                case 'brightfield'
                    colormap(ax, 'gray')
                case 'green'
                    greenColor=zeros(64,3);
                    greenColor(:,2)=linspace(0,1,64);
                    colormap(ax, greenColor);
                case 'red'
                    redColor=zeros(64,3);
                    redColor(:,1)=linspace(0,1,64);
                    colormap(ax, redColor);
                case 'blue'
                    blueColor=zeros(64,3);
                    blueColor(:,3)=linspace(0,1,64);
                    colormap(ax, blueColor);
            end
            set(ax, 'yDir', 'normal');
            onFOVChange(view, model);
            onAlignment(view, model);
        catch
            if ishandle(view.Fluorescence.plot)
                delete(view.Fluorescence.plot)
            end
            set(handles.channels, 'Items', {''});
            set(handles.channels, 'Value', '');
            set(handles.date, 'Text', '');
        end
    else
        if ishandle(view.Fluorescence.plot)
            delete(view.Fluorescence.plot)
        end
        set(handles.channels, 'Items', {''});
        set(handles.channels, 'Value', '');
        set(handles.date, 'Text', '');
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

function onAlignment(view, model)
    if ~isempty(model.Fluorescence.repetitions)
        ax = view.Fluorescence.axesImage;
        hold(ax, 'on');
        if ishandle(view.Fluorescence.positionPlot)
            delete(view.Fluorescence.positionPlot)
        end
        view.Fluorescence.positionPlot = plot(ax, ...
            model.Alignment.position.x + model.Alignment.dx, ...
            model.Alignment.position.y + model.Alignment.dy, ...
            'color', 'red', 'linewidth', 1.5);
        % If there is only a single point in x and y we use a visible
        % marker
        if length(model.Alignment.position.x) == 1 && length(model.Alignment.position.y) == 1
            view.Fluorescence.positionPlot.Marker = 'o';
        end
    end
end
