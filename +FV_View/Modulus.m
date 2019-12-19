function Modulus(view, model)
%% MODULUS View

    % build the GUI
    initGUI(model, view);
    initView(view, model);    % populate with initial values

    % observe on model changes and update view accordingly
    % (tie listener to model object lifecycle)
    addlistener(model, 'modulus', 'PostSet', ...
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
    parent = view.Modulus.parent;
    
    axesImage = axes('Parent', parent, 'Position', [0.03 .055 .26 .34]);
    axis(axesImage, 'equal');
    box(axesImage, 'on');
    
    modulusGroup = uipanel('Parent', parent, 'Title', 'Modulus parameters', 'FontSize', 11,...
             'Position', [.36 .055 .2 .35]);
    
    uicontrol('Parent', modulusGroup, 'Style', 'text', 'String', 'Refractive index n of the medium [1]:', 'Units', 'normalized',...
        'Position', [0.05,0.83,0.53,0.15], 'FontSize', 11, 'HorizontalAlignment', 'left');
    n0 = uicontrol('Parent', modulusGroup, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.6,0.85,0.35,0.1], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor');
    
    uicontrol('Parent', modulusGroup, 'Style', 'text', 'String', 'Refractive index increment [ml/g]:', 'Units', 'normalized',...
        'Position', [0.05,0.66,0.53,0.15], 'FontSize', 11, 'HorizontalAlignment', 'left');
    alpha = uicontrol('Parent', modulusGroup, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.6,0.68,0.35,0.1], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor');
    
    uicontrol('Parent', modulusGroup, 'Style', 'text', 'String', 'Absolute density of the medium [g/ml]:', 'Units', 'normalized',...
        'Position', [0.05,0.49,0.53,0.15], 'FontSize', 11, 'HorizontalAlignment', 'left');
    rho0 = uicontrol('Parent', modulusGroup, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.6,0.51,0.35,0.1], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor');
    
    uicontrol('Parent', modulusGroup, 'Style', 'text', 'String', 'Use absolute density of dry fraction', 'Units', 'normalized',...
        'Position', [0.05,0.32,0.53,0.15], 'FontSize', 11, 'HorizontalAlignment', 'left');
    useDryDensity = uicontrol('Parent', modulusGroup, 'Style', 'checkbox', 'Units', 'normalized',...
        'Position', [0.89,0.34,0.14,0.1], 'FontSize', 11, 'HorizontalAlignment', 'left', 'tag', 'Borders');
    
    rho_dry_label = uicontrol('Parent', modulusGroup, 'Style', 'text', 'String', 'Absolute density of the dry fraction [g/ml]:', 'Units', 'normalized',...
        'Position', [0.05,0.15,0.53,0.15], 'FontSize', 11, 'HorizontalAlignment', 'left', 'enable', 'off');
    rho_dry = uicontrol('Parent', modulusGroup, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.6,0.17,0.35,0.1], 'FontSize', 11, 'HorizontalAlignment', 'center', 'Tag', 'floor', 'enable', 'off');
    
    %% Return handles
    view.Modulus = struct(...
        'plot', NaN, ...
        'axesImage', axesImage, ...
        'modulusGroup', modulusGroup, ...
        'n0', n0, ...
        'alpha', alpha, ...
        'rho0', rho0, ...
        'useDryDensity', useDryDensity, ...
        'rho_dry_label', rho_dry_label, ...
        'rho_dry', rho_dry ...
	);
end

function initView(view, model)
    %% Initialize the view
    onFileChange(view, model)
end

function onFileChange(view, model)
    Brillouin =  model.Brillouin;
    Alignment =  model.Alignment;
    
    set(view.Modulus.n0, 'String', model.modulus.n0);
    set(view.Modulus.alpha, 'String', model.modulus.alpha);
    set(view.Modulus.rho0, 'String', model.modulus.rho0);
    set(view.Modulus.rho_dry, 'String', model.modulus.rho_dry);
    
    set(view.Modulus.useDryDensity, 'value', model.modulus.useDryDensity);
    if model.modulus.useDryDensity
        set(view.Modulus.rho_dry_label, 'enable', 'on');
        set(view.Modulus.rho_dry, 'enable', 'on');
    else
        set(view.Modulus.rho_dry_label, 'enable', 'off');
        set(view.Modulus.rho_dry, 'enable', 'off');
    end
        
    
    if ~(isempty(Brillouin.repetitions) || isempty(model.ODT.repetitions))
        try
            ax = view.Modulus.axesImage;
            positions = Brillouin.positions;            
            
            if ishandle(view.Modulus.plot)
                delete(view.Modulus.plot)
            end
            switch (Brillouin.dimension)
                case 0
                case 1
                    %% one dimensional case
                    M = nanmean(model.modulus.M, 4);
                    d = 1e-9*squeeze(M);
                    p = squeeze(positions.(Brillouin.nsdims{1}));
                    view.Modulus.plot = plot(ax, p, d, 'marker', 'x');
                    xlim([min(p(:)), max(p(:))]);
                    ylim([min(d(:)), max(d(:))]);
                case 2
                    %% two dimensional case
                    M = nanmean(model.modulus.M, 4);
                    d = 1e-9*squeeze(M);
                    pos.x = squeeze(positions.x) + Alignment.dx;
                    pos.y = squeeze(positions.y) + Alignment.dy;
                    pos.z = squeeze(positions.z) + Alignment.dz;
                    
                    view.Modulus.plot = imagesc(ax, pos.(Brillouin.nsdims{2})(1,:), pos.(Brillouin.nsdims{1})(:,1), d);
                    axis(ax, 'equal');
                    xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
                    ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
        %             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
                    cb = colorbar(ax);
                    ylabel(cb, '$M''$ [GPa]', 'interpreter', 'latex');
                    set(ax, 'yDir', 'normal');
                case 3
            end
            
            %% Update field of view
            onFOVChange(view, model);
        catch
            if ishandle(view.Modulus.plot)
                delete(view.Modulus.plot)
            end
        end
    else
        if ishandle(view.Modulus.plot)
            delete(view.Modulus.plot)
        end
    end
end

function onFOVChange(view, model)
    ax = view.Modulus.axesImage;
    if model.parameters.xlim(1) < model.parameters.xlim(2)
        xlim(ax, [model.parameters.xlim]);
    end
    if model.parameters.ylim(1) < model.parameters.ylim(2)
        ylim(ax, [model.parameters.ylim]);
    end
end
