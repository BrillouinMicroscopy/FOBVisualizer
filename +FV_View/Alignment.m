function handles = Alignment(parent, model)
%% ALIGNMENT View

    % build the GUI
    handles = initGUI(parent, model);
    initView(handles, model);    % populate with initial values
end

function handles = initGUI(parent, ~)

    ODT = subplot(2, 3, 1);
    box(ODT, 'on');
    BS = subplot(2, 3, 2);
    box(BS, 'on');
    map = subplot(2, 3, 3);
    box(map, 'on');
    coeff = subplot(2, 3, [4 6]);
    box(coeff, 'on');
    
    coeff_pos = get(coeff, 'position');
    coeff_pos(2) = 0.15;
    set(coeff, 'position', coeff_pos);
    
    parent.Name = 'Align ODT and Brillouin';

    start = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Start','Position',[0.1,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');
    
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'dx [µm]:', 'Units', 'normalized',...
        'Position', [0.22,0.015,0.07,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');
    dx = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.28,0.03,0.07,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'dy [µm]:', 'Units', 'normalized',...
        'Position', [0.36,0.015,0.07,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');
    dy = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.42,0.03,0.07,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center');
    
    uicontrol('Parent', parent, 'Style', 'text', 'String', 'dz [µm]:', 'Units', 'normalized',...
        'Position', [0.50,0.015,0.07,0.055], 'FontSize', 11, 'HorizontalAlignment', 'left');
    dz = uicontrol('Parent', parent, 'Style', 'edit', 'Units', 'normalized',...
        'Position', [0.56,0.03,0.07,0.055], 'FontSize', 11, 'HorizontalAlignment', 'center');

    save = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Apply','Position',[0.8,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    cancel = uicontrol('Parent', parent, 'Style', 'pushbutton', 'Units', 'normalized',...
        'String','Cancel','Position',[0.68,0.03,0.1,0.055],...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    handles = struct(...
        'parent', parent, ...
        'ODT', ODT, ...
        'ODT_plot', NaN, ...
        'BS', BS, ...
        'BS_plot', NaN, ...
        'map', map, ...
        'map_plot', NaN, ...
        'coeff', coeff, ...
        'coeff_plot', NaN, ...
        'dx', dx, ...
        'dy', dy, ...
        'dz', dz, ...
        'start', start, ...
        'save', save, ...
        'cancel', cancel ...
    );
end

function initView(view, model)
    Brillouin = model.Brillouin;
    
    set(view.dx, 'String', model.Alignment.dx);
    set(view.dy, 'String', model.Alignment.dy);
    set(view.dz, 'String', model.Alignment.dz);
    
    if ~isempty(Brillouin.repetitions)
        try
            ax = view.BS;
            BS = nanmean(Brillouin.shift, 4);
            positions = Brillouin.positions;

            dimensions = size(BS);
            dimension = sum(dimensions > 1);

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

            if ishandle(view.BS_plot)
                delete(view.BS_plot)
            end
            switch (dimension)
                case 0
                case 1
                    %% one dimensional case
                case 2
                    %% two dimensional case
                    d = squeeze(BS);
                    pos.x = squeeze(positions.x);
                    pos.y = squeeze(positions.y);
                    pos.z = squeeze(positions.z);

                    view.BS_plot = imagesc(ax, pos.(nsdims{2})(1,:), pos.(nsdims{1})(:,1), d);
                    axis(ax, 'equal');
                    xlabel(ax, '$x$ [$\mu$m]', 'interpreter', 'latex');
                    ylabel(ax, '$y$ [$\mu$m]', 'interpreter', 'latex');
        %             zlabel(ax, '$z$ [$\mu$m]', 'interpreter', 'latex');
                    cb = colorbar(ax);
                    ylabel(cb, '$\nu$ [GHz]', 'interpreter', 'latex');
                    set(ax, 'yDir', 'normal');
                case 3
            end
        catch
        end
    end
end