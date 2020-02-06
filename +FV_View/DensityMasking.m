function DensityMasking(view, model)
%% DENSITYMASKING View

    % build the GUI
    initGUI(view, model);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    listener(1) = addlistener(model, 'density', 'PostSet', ...
        @(o,e) initView(view, e.AffectedObject));
    listener(2) = addlistener(model, 'tmp', 'PostSet', ...
        @(o,e) updatePlot(view, e.AffectedObject));
    
    set(view.DensityMasking.parent, 'CloseRequestFcn', {@closeMasking, listener, model}); 
end

function initGUI(view, model)
    parent = view.DensityMasking.parent;
    
    parent.Name = 'Add density masks';
    
    axesImage = axes('Parent', parent, 'Position', [0.47 .15 .5 .8]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    
    fluorescence = {'red', 'green'};
    
    masksTable = uitable('Parent', parent, 'Units', 'normalized', 'Position', [0.02 0.15 0.4 0.8], ...
        'ColumnWidth', {96, 50, 50, 90, 50}, 'ColumnName', {'Parameter', 'Min', 'Max', 'Density [g/ml]', 'active'}, ...
        'FontSize', 10, 'ColumnEditable', true, ...
        'ColumnFormat',[{[{'Refractive index', 'Brillouin shift'}, fluorescence ]}, repmat({[]},1,3), 'logical']);
    
    deleteMask = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', FV_SharedFunctions.iconString([model.pp '/images/delete.png']),'Position',[0.170,0.1,0.035,0.05],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    addMask = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String', FV_SharedFunctions.iconString([model.pp '/images/add.png']),'Position',[0.206,0.1,0.035,0.05],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    save = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','OK','Position',[0.8,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    cancel = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Cancel','Position',[0.68,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    view.DensityMasking = struct(...
        'plot', NaN, ...
        'axesImage', axesImage, ...
        'parent', parent, ...
        'masksTable', masksTable, ...
        'addMask', addMask, ...
        'deleteMask', deleteMask, ...
        'save', save, ...
        'cancel', cancel ...
    );
end

function initView(view, model)
    masks = model.density.masks;
    masksFields = fields(masks);
    %% Update masking table
    masksData = cell(length(masksFields), 5);
    for jj = 1:length(masksFields)
        m = masks.(masksFields{jj});
        masksData(jj,:) = {m.parameter, m.min, m.max, m.density, m.active};
    end
    view.DensityMasking.masksTable.Data = masksData;

    updatePlot(view, model);
end

function updatePlot(view, model)
    %% Plot masking preview
    masks = model.density.masks;
    masksFields = fields(masks);
    if length(masksFields) < 1
        return
    end
    if model.tmp.selectedMask > length(masksFields)
        model.tmp.selectedMask = 1;
    end
    mask = masks.(masksFields{model.tmp.selectedMask});
    ax = view.DensityMasking.axesImage;
    switch (mask.parameter)
        case 'Refractive index'
            positions = model.Brillouin.positions;
            RI = model.density.RI(:, :, 1, 1);
            RI(RI > mask.max | RI < mask.min) = NaN;
            view.DensityMasking.plot = imagesc(ax, positions.x(1,:,1), positions.y(:,1,1), RI, 'AlphaData', ~isnan(RI));
            colormap(ax, 'jet');
            cb = colorbar(ax);
            ylabel(cb, '$n$', 'interpreter', 'latex');
        case 'Brillouin shift'
            positions = model.Brillouin.positions;
            BS = nanmean(model.Brillouin.shift, 4);
            BS(BS > mask.max | BS < mask.min) = NaN;
            view.DensityMasking.plot = imagesc(ax, positions.x(1,:,1), positions.y(:,1,1), BS, 'AlphaData', ~isnan(BS));
            colormap(ax, 'parula');
            cb = colorbar(ax);
            ylabel(cb, '$\nu_\mathrm{B}$ [GHz]', 'interpreter', 'latex');
        otherwise
            if ishandle(view.DensityMasking.plot)
                delete(view.DensityMasking.plot);
            end
    end
    axis(ax, 'equal');
    xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
    ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
    set(ax, 'yDir', 'normal');
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end

function closeMasking(source, ~, listener, ~)
    delete(listener);
    delete(source);
end