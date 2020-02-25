function Density(view, model)
%% DENSITY View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'density', 'PostSet', ...
        @(o,e) onFileChange(view, e.AffectedObject));
%     
%     addlistener(model, 'ODT', 'PostSet', ...
%         @(o,e) onFileChange(view, e.AffectedObject));
%     
%     addlistener(model, 'Alignment', 'PostSet', ...
%         @(o,e) onFileChange(view, e.AffectedObject));
    
    addlistener(model, 'parameters', 'PostSet', ...
        @(o,e) onFOVChange(view, e.AffectedObject));
end

function initGUI(~, view)
    parent = view.Density.parent;
    
    axesImage = uiaxes(parent, 'Position', [500 10 380 300]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    
    densityGroup = uipanel('Parent', parent, 'Title', 'Density calculation', ...
        'Position', [10 10 400 300]);
    
    uilabel(densityGroup, 'Text', {'Refractive index n of', 'the medium [1]:'}, ...
        'Position', [10 240 130 40], 'HorizontalAlignment', 'left');
    n0 = uieditfield(densityGroup, 'numeric', ...
        'Position', [150 245 100 25], 'HorizontalAlignment', 'center', 'Tag', 'floor');
    
    uilabel(densityGroup, 'Text', {'Refractive index', 'increment [ml/g]:'}, ...
        'Position', [10 200 130 40], 'HorizontalAlignment', 'left');
    alpha = uieditfield(densityGroup, 'numeric', ...
        'Position', [150 205 100 25], 'HorizontalAlignment', 'center', 'Tag', 'floor');
    
    uilabel(densityGroup, 'Text', {'Absolute density of', 'the medium [g/ml]:'}, ...
        'Position', [10 160 130 40], 'HorizontalAlignment', 'left');
    rho0 = uieditfield(densityGroup, 'numeric', ...
        'Position', [150 165 100 25], 'HorizontalAlignment', 'center', 'Tag', 'floor');
    
    uilabel(densityGroup, 'Text', {'Use absolute density', 'of dry fraction'}, ...
        'Position', [10 120 130 40], 'HorizontalAlignment', 'left');
    useDryDensity = uicheckbox(densityGroup, 'Position', [192 125 15 25], ...
        'tag', 'Borders', 'Text', '');
    
    rho_dry_label = uilabel(densityGroup, 'Text', {'Absolute density of', 'the dry fraction [g/ml]:'}, ...
        'Position', [10 80 130 40], 'HorizontalAlignment', 'left', 'enable', 'off');
    rho_dry = uieditfield(densityGroup, 'numeric', ...
        'Position', [150 85 100 25], 'HorizontalAlignment', 'center', 'Tag', 'floor', 'enable', 'off');

    openMasking = uibutton(densityGroup, 'Text', 'Masking', 'Position', [150 45 100 25], 'BackgroundColor', [.9 .9 .9]);
    
    %% Return handles
    view.Density = struct(...
        'plot', NaN, ...
        'axesImage', axesImage, ...
        'densityGroup', densityGroup, ...
        'n0', n0, ...
        'alpha', alpha, ...
        'rho0', rho0, ...
        'useDryDensity', useDryDensity, ...
        'rho_dry_label', rho_dry_label, ...
        'rho_dry', rho_dry, ...
        'openMasking', openMasking ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileChange(view, model)
end

function onFileChange(view, model)
    Brillouin = model.Brillouin;
    Alignment = model.Alignment;
    
    set(view.Density.n0, 'Value', model.density.n0);
    set(view.Density.alpha, 'Value', model.density.alpha);
    set(view.Density.rho0, 'Value', model.density.rho0);
    set(view.Density.rho_dry, 'Value', model.density.rho_dry);
    
    set(view.Density.useDryDensity, 'Value', model.density.useDryDensity);
    if model.density.useDryDensity
        set(view.Density.rho_dry_label, 'enable', 'on');
        set(view.Density.rho_dry, 'enable', 'on');
    else
        set(view.Density.rho_dry_label, 'enable', 'off');
        set(view.Density.rho_dry, 'enable', 'off');
    end
        
    
    if ~(isempty(Brillouin.repetitions) || isempty(model.ODT.repetitions))
        try
            ax = view.Density.axesImage;
            positions = Brillouin.positions;            
            
            if ishandle(view.Density.plot)
                delete(view.Density.plot)
            end
            switch (Brillouin.dimension)
                case 0
                case 1
                    %% one dimensional case
                    rho = nanmean(model.density.rho, 4);
                    d = 1e-3*squeeze(rho);
                    p = squeeze(positions.(Brillouin.nsdims{1})) + Alignment.(['d' Brillouin.nsdims{1}]);
                    view.Density.plot = plot(ax, p, d, 'marker', 'x');
                    xlim(ax, [min(p(:)), max(p(:))]);
                    ylim(ax, [min(d(:)), max(d(:))]);
                    xlabel(ax, ['$' Brillouin.nsdims{1} '$ [$\mu$m]'], 'interpreter', 'latex');
                    ylabel(ax, '$\rho$ [g/ml]', 'interpreter', 'latex');
                case 2
                    %% two dimensional case
                    rho = nanmean(model.density.rho, 4);
                    d = 1e-3*squeeze(rho);
                    pos.x = squeeze(positions.x) + Alignment.dx;
                    pos.y = squeeze(positions.y) + Alignment.dy;
                    pos.z = squeeze(positions.z) + Alignment.dz;
                    
                    view.Density.plot = imagesc(ax, pos.(Brillouin.nsdims{2})(1,:), pos.(Brillouin.nsdims{1})(:,1), d);
                    axis(ax, 'equal');
                    xlabel(ax, ['$' Brillouin.nsdims{2} '$ [$\mu$m]'], 'interpreter', 'latex');
                    ylabel(ax, ['$' Brillouin.nsdims{1} '$ [$\mu$m]'], 'interpreter', 'latex');
        %             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
                    cb = colorbar(ax);
                    ylabel(cb, '$\rho$ [g/ml]', 'interpreter', 'latex');
                    set(ax, 'yDir', 'normal');
                case 3
            end
            
            %% Update field of view
            onFOVChange(view, model);
        catch
            if ishandle(view.Density.plot)
                delete(view.Density.plot)
            end
        end
    else
        if ishandle(view.Density.plot)
            delete(view.Density.plot)
        end
    end
end

function onFOVChange(view, model)
    if model.Brillouin.dimension ~= 2
        return
    end
    ax = view.Density.axesImage;
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end
