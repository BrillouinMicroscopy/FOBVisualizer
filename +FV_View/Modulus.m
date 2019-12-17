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
    
    %% Return handles
    view.Modulus = struct(...
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
    Alignment =  model.Alignment;
    
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
