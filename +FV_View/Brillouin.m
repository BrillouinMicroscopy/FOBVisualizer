function Brillouin(view, model)
%% BRILLOUIN View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'Brillouin', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.Brillouin.parent;
    
    uicontrol('Parent', parent, 'Style','text','String','Brillouin repetition:', 'Units', 'normalized',...
               'Position',[0.67,0.885,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetition = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized',...
               'Position',[0.80,0.91,0.05,0.005], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', {''});
    uicontrol('Parent', parent, 'Style','text','String','of', 'Units', 'normalized',...
               'Position',[0.86,0.885,0.02,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetitionCount = uicontrol('Parent', parent, 'Style','text','String','0', 'Units', 'normalized',...
               'Position',[0.88,0.885,0.02,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    uicontrol('Parent', parent, 'Style','text','String','Date:', 'Units', 'normalized',...
               'Position',[0.67,0.85,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    date = uicontrol('Parent', parent, 'Style','text','String','', 'Units', 'normalized',...
               'Position',[0.80,0.85,0.19,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    axesImage = axes('Parent', parent, 'Position', [0.69 .46 .26 .34]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    
    %% Return handles
    view.Brillouin = struct(...
        'parent', parent, ...
        'repetition', repetition, ...
        'repetitionCount', repetitionCount, ...
        'plot', NaN, ...
        'date', date, ...
        'axesImage', axesImage ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileChange(view, model)
end

function onFileChange(view, model)
    Brillouin = model.Brillouin;
    handles = view.Brillouin;
    reps = Brillouin.repetitions;
    if (isempty(reps))
        set(handles.repetitionCount, 'String', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'String', length(reps));
    end
    set(handles.repetition, 'String', reps);
    set(handles.repetition, 'Value', Brillouin.repetition.index);
    
    if ~isempty(Brillouin.repetitions)
        try
            ax = handles.axesImage;
            
            BS = nanmean(Brillouin.shift, 4);
            positions = Brillouin.positions;
            
            dimensions = size(BS);
            dimension = sum(dimensions > 1);
            Brillouin.dimension = dimension;
            
            %% find non-singular dimensions
            dims = {'y', 'x', 'z'};
            nsdims = cell(dimension,1);
            sdims = cell(dimension,1);
            ind = 0;
            sind = 0;
            for jj = 1:length(dimensions)
                if dimensions(jj) > 1
                    ind = ind + 1;
                    nsdims{ind} = dims{jj};
                else
                    sind = sind + 1;
                    sdims{sind} = dims{jj};
                end
            end
            Brillouin.nsdims = nsdims;
            
            if ishandle(view.Brillouin.plot)
                delete(view.Brillouin.plot)
            end
            switch (dimension)
                case 0
                case 1
                    %% one dimensional case
                    d = squeeze(BS);
                    p = squeeze(positions.(nsdims{1}));
                    view.Brillouin.plot = plot(ax, p, d, 'marker', 'x');
                    xlim([min(p(:)), max(p(:))]);
                    ylim([min(d(:)), max(d(:))]);

                    %% Extract positions to show in ODT and Fluorescence
                    xPos = nanmean(positions.(sdims{2})(:));
                    Brillouin.position.x = xPos;
                    yPos = nanmean(positions.(sdims{1})(:));
                    Brillouin.position.y = yPos;
                case 2
                    %% two dimensional case
                    d = squeeze(BS);
                    pos.x = squeeze(positions.x);
                    pos.y = squeeze(positions.y);
                    pos.z = squeeze(positions.z);
                    
                    view.Brillouin.plot = imagesc(ax, pos.(nsdims{2})(1,:), pos.(nsdims{1})(:,1), d);
                    axis(ax, 'equal');
                    xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
                    ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
        %             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
                    cb = colorbar(ax);
                    ylabel(cb, '$\nu$ [GHz]', 'interpreter', 'latex');
                    set(ax, 'yDir', 'normal');

                    %% Extract positions to show in ODT and Fluorescence
                    minX = min(positions.x(:));
                    maxX = max(positions.x(:));
                    xPos = [minX, maxX, maxX, minX, minX];
                    Brillouin.position.x = xPos;
                    minY = min(positions.y(:));
                    maxY = max(positions.y(:));
                    yPos = [minY, minY, maxY, maxY, minY];
                    Brillouin.position.y = yPos;
                case 3
            end
            set(handles.date, 'String', Brillouin.date);
            
            model.Brillouin = Brillouin;
            %% Update field of view
            onFOVChange(view, model);
        catch
            if ishandle(view.Brillouin.plot)
                delete(view.Brillouin.plot)
            end
            set(handles.date, 'String', '');
        end
    else
        if ishandle(view.Brillouin.plot)
            delete(view.Brillouin.plot)
        end
        set(handles.date, 'String', '');
    end
    model.Brillouin = Brillouin;
end

function onFOVChange(view, model)
    if (model.Brillouin.dimension == 2)
        ax = view.Brillouin.axesImage;
        if model.parameters.xlim(1) < model.parameters.xlim(2)
            xlim(ax, [model.parameters.xlim]);
        end
        if model.parameters.ylim(1) < model.parameters.ylim(2)
            ylim(ax, [model.parameters.ylim]);
        end
    end
end
