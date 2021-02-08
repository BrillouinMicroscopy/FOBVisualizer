function callbacks = Brillouin(model, view)
%% DATA Controller

    %% general panel
    set(view.Brillouin.repetition, 'ValueChangedFcn', {@selectRepetition, model});

    callbacks = struct( ...
        'loadRepetition', @()loadRepetition(model, model.Brillouin.repetition), ...
        'extractAlignment', @(Alignment)extractAlignment(model, Alignment) ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    items = get(src, 'Items');
    repetition.index = find(strcmp(items, val));
    repetition.name = model.Brillouin.repetitions{repetition.index};
    
    loadRepetition(model, repetition);

    % Load the alignment from file
    model.controllers.data.loadAlignmentData();
end

function loadRepetition(model, repetition)
    Brillouin = model.Brillouin;
    Brillouin.repetition = repetition;
    
    if ~isempty(Brillouin.repetitions)
        try
            [~, name, ~] = fileparts(model.filename);
            if length(Brillouin.repetitions) > 1
                name = [name '_rep' num2str(Brillouin.repetition.name)];
            end
            filepath = [model.filepath '..' filesep 'EvalData' filesep name '.mat'];
            data = load(filepath, 'results');
            
            Brillouin.date = model.file.readPayloadData('Brillouin', Brillouin.repetition.name, 'date', 0);
                
            
            if isfield(data.results.results, 'BrillouinShift_frequency_normalized')
                Brillouin.shift = data.results.results.BrillouinShift_frequency_normalized;
            else
                Brillouin.shift = data.results.results.BrillouinShift_frequency;
            end
            Brillouin.positions.x = data.results.parameters.positions.X;
            Brillouin.positions.y = data.results.parameters.positions.Y;
            Brillouin.positions.z = data.results.parameters.positions.Z;
            
            Brillouin.intensity = data.results.results.peaksBrillouin_int;
            Brillouin.validity = data.results.results.validity;
            
            Brillouin.validityLevel = data.results.results.peaksBrillouin_dev./data.results.results.peaksBrillouin_int;
            
            % Get the dimensions of x, y and z
            dimensions = size(Brillouin.shift, 1, 2, 3);
            
            dimension = sum(dimensions > 1);
            Brillouin.dimension = dimension;
            
            %% find non-singular dimensions
            dims = {'y', 'x', 'z'};
            nsdims = cell(0);
            sdims = cell(0);
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
            Brillouin.sdims = sdims;
            
        catch
            Brillouin.data = NaN;
            Brillouin.date = '';
            Brillouin.positions = struct( ...
                'x', [], ...
                'y', [], ...
                'z', [] ...
            );
            Brillouin.nsdims = [];
            Brillouin.sdims = [];
        end
    end
    
    model.Brillouin = Brillouin;
    extractAlignment(model);
    model.controllers.density.calculateDensity();
end

function extractAlignment(model, Alignment)
    try
        if nargin < 2
            Alignment = model.Alignment;
        end
        Brillouin = model.Brillouin;
        %% Extract limits of positions to show in ODT and Fluorescence
        lims = struct();
        for dim = 1:length(Brillouin.sdims)
            lims.(Brillouin.sdims{dim}) = nanmean(Brillouin.positions.(Brillouin.sdims{dim}), 'all');
        end
        for dim = 1:length(Brillouin.nsdims)
            lims.(Brillouin.nsdims{dim}) = [min(Brillouin.positions.(Brillouin.nsdims{dim}), [], 'all'), ...
                                            max(Brillouin.positions.(Brillouin.nsdims{dim}), [], 'all')];
        end
        %% Construct lines to indicate the positions
        Alignment.position.x = [];
        Alignment.position.y = [];
        % number of edges we have to draw is 2^(dimension - 1) * dimension, but
        % we only consider the projection in the x-y-plane.
        xydim = sum(size(Brillouin.shift, 1, 2) > 1);
        switch 2^(xydim - 1) * xydim
            % Show a single point
            case 0
                for jj = 1:length(lims.x)
                    for kk = 1:length(lims.y)
                        Alignment.position.x(end+1) = lims.x(jj);
                        Alignment.position.y(end+1) = lims.y(kk);
                    end
                end
            % Show a line
            case 1
                for jj = 1:length(lims.x)
                    for kk = 1:length(lims.y)
                        Alignment.position.x(end+1) = lims.x(jj);
                        Alignment.position.y(end+1) = lims.y(kk);

                        if jj == kk
                            Alignment.position.x(end+1) = lims.x(mod(jj + 1, 2) + 1);
                            Alignment.position.y(end+1) = lims.y(kk);
                        else
                            Alignment.position.x(end+1) = lims.x(jj);
                            Alignment.position.y(end+1) = lims.y(mod(kk + 1, 2) + 1);
                        end
                    end
                end
            % Show a square
            case 4
                for jj = 1:length(lims.x)
                    for kk = 1:length(lims.y)
                        Alignment.position.x(end+1) = lims.x(jj);
                        Alignment.position.y(end+1) = lims.y(kk);

                        if jj == kk
                            Alignment.position.x(end+1) = lims.x(mod(jj, 2) + 1);
                            Alignment.position.y(end+1) = lims.y(kk);
                        else
                            Alignment.position.x(end+1) = lims.x(jj);
                            Alignment.position.y(end+1) = lims.y(mod(kk, 2) + 1);
                        end
                        Alignment.position.x(end+1) = NaN;
                        Alignment.position.y(end+1) = NaN;
                    end
                end
            case 12
                % We only consider the projection to the x-y-plane, so this
                % case won't occur.
        end
        model.Alignment = Alignment;
    catch
    end
end