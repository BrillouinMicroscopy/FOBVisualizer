function ODT(view, model)
%% ODT View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'ODT', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'Alignment', 'PostSet', ...
        @(o,e) onAlignment(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
end

function initGUI(model, view)
    parent = view.ODT.parent;
    
    uilabel(parent, 'Text', 'ODT repetition:', 'Position', [10 710 100 20], ...
        'HorizontalAlignment', 'left');
    repetition = uidropdown(parent, 'Position', [140 710 100 20], ...
        'Items', {''});
    uilabel(parent, 'Text', 'of', 'Position', [260 710 30 20], ...
        'HorizontalAlignment', 'left');
    repetitionCount = uilabel(parent, 'Text', '0', 'Position', [290 710 30 20], ...
        'HorizontalAlignment', 'left');
    
    uilabel(parent, 'Text', 'Date:', 'Position', [10 690 100 20], ...
        'HorizontalAlignment', 'left');
    date = uilabel(parent, 'Text', '', 'Position', [140 690 300 20], ...
        'HorizontalAlignment', 'left');
    
    uilabel(parent, 'Text', 'Max. proj.:','Position', [10 670 100 20], ...
        'HorizontalAlignment', 'left');
    maxProj = uicheckbox(parent, 'Position', [70 670 100 20], ...
        'FontSize', 11, 'tag', 'Borders', 'value', model.ODT.maxProj, 'Text', '');
    
    uilabel(parent, 'Text', 'z [µm]:', 'Position', [90 670 80 20], ...
        'HorizontalAlignment', 'left');
	zDepth = uislider(parent, 'Position', [140 680 280 3], 'Limits', [-10 10], 'MajorTicks', [-10 -8 -6 -4 -2 0 2 4 6 8 10], ...
        'Value', model.ODT.zDepth, 'Enable', ~model.ODT.maxProj);
    
    axesImage = uiaxes(parent, 'Position', [30 350 390 300]);
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
        set(handles.repetitionCount, 'Text', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'Text', num2str(length(reps)));
    end
    set(handles.repetition, 'Items', reps);
    set(handles.repetition, 'Value', ODT.repetition.name);
    
    set(handles.maxProj, 'Value', ODT.maxProj);
    set(handles.zDepth, 'Enable', ~ODT.maxProj);
    
    if ~isempty(ODT.repetitions)
        try
            ax = handles.axesImage;
            
            set(handles.date, 'Text', ODT.date);
            
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
            xlabel(ax, '{\it x} [µm]', 'interpreter', 'tex');
            ylabel(ax, '{\it y} [µm]', 'interpreter', 'tex');
            colormap(ax, 'jet');
            cb = colorbar(ax);
            ylabel(cb, '{\it n}', 'interpreter', 'tex', 'FontSize', 10);
            caxis(ax, [n_m-.005 n_s]);
            set(ax, 'yDir', 'normal');
%             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
            onFOVChange(view, model);
            onAlignment(view, model);
        catch
            if ishandle(view.ODT.plot)
                delete(view.ODT.plot)
            end
            set(handles.date, 'Text', '');
        end
    else
        if ishandle(view.ODT.plot)
            delete(view.ODT.plot)
        end
        set(handles.date, 'Text', '');
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

function onAlignment(view, model)
    if ~isempty(model.ODT.repetitions)
        ax = view.ODT.axesImage;
        hold(ax, 'on');
        if ishandle(view.ODT.positionPlot)
            delete(view.ODT.positionPlot)
        end
        view.ODT.positionPlot = plot(ax, ...
            model.Alignment.position.x + model.Alignment.dx, ...
            model.Alignment.position.y + model.Alignment.dy, ...
            'color', 'red', 'linewidth', 1.5);
        % If there is only a single point in x and y we use a visible
        % marker
        if length(model.Alignment.position.x) == 1 && length(model.Alignment.position.y) == 1
            view.ODT.positionPlot.Marker = 'o';
        end
    end
end
