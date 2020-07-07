function Brillouin(view, model)
%% BRILLOUIN View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'Brillouin', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'Alignment', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.Brillouin.parent;
    
    uilabel(parent, 'Text', 'Brillouin repetition:', 'Position', [930 710 100 20], ...
        'HorizontalAlignment', 'left');
    repetition = uidropdown(parent, 'Position', [1060 710 100 20], ...
        'Items', {''});
    uilabel(parent, 'Text', 'of', 'Position', [1180 710 30 20], ...
        'HorizontalAlignment', 'left');
    repetitionCount = uilabel(parent, 'Text', '0', 'Position', [1210 710 30 20], ...
        'HorizontalAlignment', 'left');
    
    uilabel(parent, 'Text', 'Date:', 'Position', [930 690 100 20], ...
        'HorizontalAlignment', 'left');
    date = uilabel(parent, 'Text', '', 'Position', [1060 690 300 20], ...
        'HorizontalAlignment', 'left');
    
    axesImage = uiaxes(parent, 'Position', [960 350 390 300]);
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

function onFileChange(FOB_view, model)
    Brillouin = model.Brillouin;
    Alignment = model.Alignment;
    handles = FOB_view.Brillouin;
    reps = Brillouin.repetitions;
    if (isempty(reps))
        set(handles.repetitionCount, 'Text', num2str(0));
        reps = {''};
    else
        set(handles.repetitionCount, 'Text', num2str(length(reps)));
    end
    set(handles.repetition, 'Items', reps);
    set(handles.repetition, 'Value', Brillouin.repetition.name);
    
    if ~isempty(Brillouin.repetitions)
        try
            ax = handles.axesImage;
            positions = Brillouin.positions;
            
            for jj = 1:length(FOB_view.Brillouin.plot)
                if ishandle(FOB_view.Brillouin.plot(jj))
                    delete(FOB_view.Brillouin.plot(jj))
                end
            end
            BS = nanmean(Brillouin.shift, 4);
            d = squeeze(BS);
            switch (Brillouin.dimension)
                case 0
                case 1
                    %% one dimensional case
                    p = squeeze(positions.(Brillouin.nsdims{1})) + Alignment.(['d' Brillouin.nsdims{1}]);
                    FOB_view.Brillouin.plot = plot(ax, p, d, 'marker', 'x');
                    axis(ax, 'normal');
                    colorbar(ax, 'off');
                    xlim(ax, [min(p(:)), max(p(:))]);
                    ylim(ax, [min(d(:)), max(d(:))]);
                    xlabel(ax, ['{\it ' Brillouin.nsdims{1} '} [µm]'], 'interpreter', 'tex');
                    ylabel(ax, '\nu_{B} [GHz]', 'interpreter', 'tex');
                    zlabel(ax, '');
                    if strcmp(Brillouin.nsdims{1}, 'z')
                        hold(ax, 'on');
                        plot(ax, [Alignment.z0, Alignment.z0], [min(d(:)), max(d(:))], 'Linewidth', 1.5, 'color', [0.4660, 0.6740, 0.1880]);
                        hold(ax, 'off');
                    end
                    view(ax, 2);
                case 2
                    %% two dimensional case
                    pos.x = squeeze(positions.x) + Alignment.dx;
                    pos.y = squeeze(positions.y) + Alignment.dy;
                    pos.z = squeeze(positions.z) + Alignment.dz;
                    
                    FOB_view.Brillouin.plot = imagesc(ax, pos.(Brillouin.nsdims{2})(1,:), pos.(Brillouin.nsdims{1})(:,1), d);
                    axis(ax, 'equal');
                    xlabel(ax, ['{\it ' Brillouin.nsdims{2} '} [µm]'], 'interpreter', 'tex');
                    ylabel(ax, ['{\it ' Brillouin.nsdims{1} '} [µm]'], 'interpreter', 'tex');
        %             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
                    cb = colorbar(ax);
                    ylabel(cb, '\nu_{B} [GHz]', 'interpreter', 'tex', 'FontSize', 10);
                    set(ax, 'yDir', 'normal');
                    view(ax, 2);
                case 3
                    %% three dimensional case
                    pos.x = squeeze(positions.x) + Alignment.dx;
                    pos.y = squeeze(positions.y) + Alignment.dy;
                    pos.z = squeeze(positions.z) + Alignment.dz;
                    
                    if ndims(pos.x) ~= ndims(d) || sum(size(pos.x) ~= size(d)) > 0
                        return;
                    end
                    FOB_view.Brillouin.plot = NaN(size(d, 3), 1);
                    for jj = 1:size(d, 3)
                        FOB_view.Brillouin.plot(jj) = surf(ax, pos.x(:,:,jj), pos.y(:,:,jj), pos.z(:,:,jj), d(:,:,jj));
                        hold(ax, 'on');
                    end
                    cb = colorbar(ax);
                    ylabel(cb, '\nu_{B} [GHz]', 'interpreter', 'tex', 'FontSize', 10);
                    set(ax, 'yDir', 'normal');
                    shading(ax, 'flat');
                    axis(ax, 'equal');
                    xlabel(ax, ['{\it ' Brillouin.nsdims{2} '} [µm]'], 'interpreter', 'tex');
                    ylabel(ax, ['{\it ' Brillouin.nsdims{1} '} [µm]'], 'interpreter', 'tex');
                    zlabel(ax, ['{\it ' Brillouin.nsdims{3} '} [µm]'], 'interpreter', 'tex');
                    xlim(ax, [min(pos.x(:)), max(pos.x(:))]);
                    ylim(ax, [min(pos.y(:)), max(pos.y(:))]);
                    zlim(ax, [min(pos.z(:)), max(pos.z(:))]);
            end
            set(handles.date, 'Text', Brillouin.date);
            %% Update field of view
            onFOVChange(FOB_view, model);
        catch
            for jj = 1:length(FOB_view.Brillouin.plot)
                if ishandle(FOB_view.Brillouin.plot(jj))
                    delete(FOB_view.Brillouin.plot(jj))
                end
            end
            set(handles.date, 'Text', '');
        end
    else
        for jj = 1:length(FOB_view.Brillouin.plot)
            if ishandle(FOB_view.Brillouin.plot(jj))
                delete(FOB_view.Brillouin.plot(jj))
            end
        end
        set(handles.date, 'Text', '');
    end
end

function onFOVChange(view, model)
    if model.Brillouin.dimension ~= 2
        return;
    end
    ax = view.Brillouin.axesImage;
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end
