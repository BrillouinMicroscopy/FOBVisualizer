function callbacks = DensityMasking(model, view)
%% DENSITYMASKING Controller
%     
    set(view.DensityMasking.addMask, 'Callback', {@addMask, model});
    set(view.DensityMasking.deleteMask, 'Callback', {@deleteMask, model});
    
    set(view.DensityMasking.masksTable, 'CellSelectionCallback', {@selectMask, model, view});
    set(view.DensityMasking.masksTable, 'CellEditCallback', {@editMask, model});
    
    set(view.DensityMasking.save, 'Callback', {@save, view});
    set(view.DensityMasking.cancel, 'Callback', {@cancel, model, view});
    
    %% general panel

    callbacks = struct( ...
    );
end

function addMask(~, ~, model)
    masks = model.density.masks;
    % Find new mask name
    jj = 0;
    newMask = sprintf('m%02.0f', jj);
    while isfield(masks, newMask)
        jj = jj + 1;
        newMask = sprintf('m%02.0f', jj);
    end
    masks.(newMask) = struct( ...
        'parameter',    'Refractive index', ...
        'min',          1.33, ...
        'max',          1.35, ...
        'density',      1.0, ...
        'active',       true ...
    );

    model.density.masks = masks;
    model.controllers.density.calculateDensity();
end

function deleteMask(~, ~, model)
    masks = model.density.masks;
    selected = model.tmp.selectedMask;
    if isempty(selected)
        return
    end
    maskFields = fields(masks);
    if selected > length(maskFields)
        return
    end
    if isfield(masks, maskFields{selected})
        masks = rmfield(masks, maskFields{selected});
    end
    maskFields = fields(masks);
    if ~isempty(maskFields)
        model.density.selectedMask = 1;
    else
        model.density.selectedMask = '';
    end
    model.density.masks = masks;
    model.controllers.density.calculateDensity();
end

function selectMask(~, data, model, ~)
    if ~isempty(data.Indices)
        selectedMask = data.Indices(1);
        model.tmp.selectedMask = selectedMask;
    end
end

function editMask(~, data, model)
    masks = model.density.masks;
    maskFields = fieldnames(masks);
    selectedMask = maskFields{data.Indices(1)};
    switch data.Indices(2)
        case 1
            model.density.masks.(selectedMask).parameter = data.NewData;
        case 2
            model.density.masks.(selectedMask).min = data.NewData;
        case 3
            model.density.masks.(selectedMask).max = data.NewData;
        case 4
            model.density.masks.(selectedMask).density = data.NewData;
        case 5
            model.density.masks.(selectedMask).active = data.NewData;
    end
    model.controllers.density.calculateDensity();
end

function save(~, ~, view)
    close(view.DensityMasking.parent);
end

function cancel(~, ~, model, view)
    model.density.masks = model.tmp.masks;
    close(view.DensityMasking.parent);
    model.controllers.density.calculateDensity();
end