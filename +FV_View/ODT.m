function ODT(view, model)
%% ODT View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'ODT', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
    
    addlistener(model, 'Brillouin', 'PostSet', ...
        @(o,e) onBrillouinChange(view, e.AffectedObject));
end

function initGUI(model, view)
    parent = view.ODT.parent;
    
    uicontrol('Parent', parent, 'Style','text','String','ODT repetition:', 'Units', 'normalized',...
               'Position',[0.01,0.885,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetition = uicontrol('Parent', parent, 'Style','popup', 'Units', 'normalized',...
               'Position',[0.14,0.91,0.05,0.005], 'FontSize', 11, 'HorizontalAlignment', 'left', 'String', {''});
    uicontrol('Parent', parent, 'Style','text','String','of', 'Units', 'normalized',...
               'Position',[0.20,0.885,0.02,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    repetitionCount = uicontrol('Parent', parent, 'Style','text','String','0', 'Units', 'normalized',...
               'Position',[0.22,0.885,0.02,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    uicontrol('Parent', parent, 'Style','text','String','Date:', 'Units', 'normalized',...
               'Position',[0.01,0.85,0.15,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    date = uicontrol('Parent', parent, 'Style','text','String','', 'Units', 'normalized',...
               'Position',[0.14,0.85,0.19,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    maxProj = uicontrol('Parent', parent, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.06,0.815,0.01,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Borders', 'value', model.ODT.maxProj);
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'Max. proj.:', 'Units', 'normalized',...
        'Position', [0.01,0.815,0.05,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
           
    uicontrol('Parent', parent, 'Style','text','String', 'z [µm]:', 'Units', 'normalized',...
               'Position',[0.08,0.815,0.05,0.025], 'FontSize', 11, 'HorizontalAlignment', 'left');
    
    zDepth = javax.swing.JSlider;
    zDepth.setEnabled(~model.ODT.maxProj);
    javacomponent(zDepth, [160, 645, 260,35], parent);
    set(zDepth, 'MajorTickSpacing', 2, 'PaintLabels', true, 'PaintTicks', true, 'Minimum', -10, 'Maximum', 10);
    zDepth.setValue(model.ODT.zDepth);
    
    axesImage = axes('Parent', parent, 'Position', [0.03 .46 .26 .34]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    
    %% Return handles
    view.ODT = struct(...
        'parent', parent, ...
        'repetition', repetition, ...
        'repetitionCount', repetitionCount, ...
        'maxProj', maxProj, ...
        'plot', NaN, ...
        'date', date, ...
        'zDepth', zDepth, ...
        'positionPlot', NaN, ...
        'axesImage', axesImage ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileChange(view, model)
end

function onFileChange(view, model)
    ODT = model.ODT;
    handles = view.ODT;
    reps = ODT.repetitions;
    if (isempty(reps))
        set(handles.repetitionCount, 'String', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'String', length(reps));
    end
    set(handles.repetition, 'String', reps);
    set(handles.repetition, 'Value', ODT.repetition.index);
    
    set(handles.maxProj, 'Value', ODT.maxProj);
    set(handles.zDepth, 'Enabled', ~ODT.maxProj);
    
    if ~isempty(ODT.repetitions)
        try
            ax = handles.axesImage;
            
            set(handles.date, 'String', ODT.date);
            
            positions = ODT.positions;
            
            n_m=1.337;
            %         end
            n_s=1.377;
            
            if ishandle(view.ODT.plot)
                delete(view.ODT.plot)
            end
            
            if (ODT.maxProj)
                slice = max(real(ODT.data.Reconimg), [], 3);
            else
                z = squeeze(positions.z(1, 1, :));
                [~, zInd] = min(abs(z - model.ODT.zDepth));
                clear z;
                slice = ODT.data.Reconimg(:, :, zInd);
            end
            
            view.ODT.plot = imagesc(ax, positions.x(1,:,1), positions.y(:,1,1), slice);
            axis(ax, 'equal');
            xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
            ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
            colormap(ax, 'jet');
            cb = colorbar(ax);
            ylabel(cb, '$n$', 'interpreter', 'latex');
            caxis(ax, [n_m-0.005 n_s]);
            set(ax, 'yDir', 'normal');
%             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
            onFOVChange(view, model);
            onBrillouinChange(view, model);
        catch
            if ishandle(view.ODT.plot)
                delete(view.ODT.plot)
            end
            set(handles.date, 'String', '');
        end
    else
        if ishandle(view.ODT.plot)
            delete(view.ODT.plot)
        end
        set(handles.date, 'String', '');
    end
end

function onFOVChange(view, model)
    ax = view.ODT.axesImage;
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end

function onBrillouinChange(view, model)
    if ~isempty(model.ODT.repetitions)
        ax = view.ODT.axesImage;
        hold(ax, 'on');
        if ishandle(view.ODT.positionPlot)
            delete(view.ODT.positionPlot)
        end
        if length(model.Brillouin.position.x) == 1
            view.ODT.positionPlot = plot(ax, model.Brillouin.position.x, model.Brillouin.position.y, 'color', 'red', 'linewidth', 1.5, 'marker', 'o');
        else
            view.ODT.positionPlot = plot(ax, model.Brillouin.position.x, model.Brillouin.position.y, 'color', 'red', 'linewidth', 1.5);
        end
    end
end
