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
    
    uicontrol('Parent', parent, 'Style','text','String','Image type:', 'Units', 'normalized',...
               'Position',[0.34,0.85,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    type = uicontrol('Parent', parent, 'Style','text','String','', 'Units', 'normalized',...
               'Position',[0.47,0.85,0.10,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    axesImage = axes('Parent', parent, 'Position', [0.34 .06 .30 .76]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
             
    %% Return handles
    view.Fluorescence = struct(...
        'parent', parent, ...
        'repetition', repetition, ...
        'repetitionCount', repetitionCount, ...
        'type', type, ...
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
            ax = handles.axesImage;
            type = model.file.readPayloadData('Fluorescence', Fluorescence.repetition, 'channel', 0);
            set(handles.type, 'String', type);
            image = model.file.readPayloadData('Fluorescence', Fluorescence.repetition, 'data', 0);
            
            x = 4.8*(1:size(image, 1))/57;
            x = x - nanmean(x(:));
            y = 4.8*(1:size(image, 2))/57;
            y = y - nanmean(y(:));
    
            imagesc(ax, x, y, image);
            shading(ax, 'flat');
            axis(ax, 'equal');
            xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
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
            onFOVChange(view, model);
        catch
            set(handles.type, 'String', '');
        end
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
