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
    
    axesImage = axes('Parent', parent, 'Position', [0.67 .06 .30 .76]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    
    %% Return handles
    view.Brillouin = struct(...
        'parent', parent, ...
        'repetition', repetition, ...
        'repetitionCount', repetitionCount, ...
        'plot', NaN, ...
        'axesImage', axesImage ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileChange(view, model)
end

function onFileChange(view, model)
    Brillouin =  model.Brillouin;
    handles = view.Brillouin;
    reps = Brillouin.repetitions;
    if (isempty(reps))
        set(handles.repetitionCount, 'String', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'String', length(reps));
    end
    set(handles.repetition, 'String', reps);
    set(handles.repetition, 'Value', Brillouin.repetition+1);
    
    if ~isempty(Brillouin.repetitions)
        try
            ax = handles.axesImage;
            
            [~, name, ~] = fileparts(model.filename);
            if length(Brillouin.repetitions) > 1
                name = [name '_rep' num2str(Brillouin.repetition)];
            end
            filepath = [model.filepath '..\EvalData\' name '.mat'];
            data = load(filepath, 'results');
            
            BrillouinShift = nanmean(data.results.results.BrillouinShift_frequency, 4);
            
            %% two dimensional case
            x = data.results.parameters.positions.X;
            y = data.results.parameters.positions.Y;
%             z = data.results.parameters.positions.Z;
            view.Brillouin.plot = imagesc(ax, x(1,:), y(:,1), BrillouinShift);
            axis(ax, 'equal');
            xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
%             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
            colorbar(ax);
            
            %% Extract positions to show in ODT and Fluorescence
            minX = min(x(:));
            maxX = max(x(:));
            xPos = [minX, maxX, maxX, minX, minX];
            Brillouin.position.x = xPos;
            minY = min(y(:));
            maxY = max(y(:));
            yPos = [minY, minY, maxY, maxY, minY];
            Brillouin.position.y = yPos;
            
            model.Brillouin = Brillouin;
            %% Update field of view
            onFOVChange(view, model);
        catch
            imagesc(ax, NaN);
        end
    else
        if ishandle(view.Brillouin.plot)
            delete(view.Brillouin.plot)
        end
    end
end

function onFOVChange(view, model)
    ax = view.Brillouin.axesImage;
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end
