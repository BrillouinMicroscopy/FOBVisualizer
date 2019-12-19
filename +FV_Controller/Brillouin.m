function callbacks = Brillouin(model, view)
%% DATA Controller

    %% general panel
    set(view.Brillouin.repetition, 'Callback', {@selectRepetition, model});

    callbacks = struct( ...
        'loadRepetition', @()loadRepetition(model, model.Brillouin.repetition), ...
        'extractAlignment', @(Alignment)extractAlignment(model, Alignment) ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    repetition.index = val;
    repetition.name = model.Brillouin.repetitions{val};
    
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
            
            dimensions = size(nanmean(Brillouin.shift, 4));
            dimension = sum(dimensions > 1);
            Brillouin.dimension = dimension;
            
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
            Brillouin.sdims = sdims;
            
        catch
            Brillouin.data = NaN;
            Brillouin.date = '';
            Brillouin.positions = struct( ...
                'x', [], ...
                'y', [], ...
                'z', [] ...
            );
        end
    end
    
    model.Brillouin = Brillouin;
    extractAlignment(model);
    model.controllers.modulus.calculateModulus();
end

function extractAlignment(model, Alignment)
    if nargin < 2
        Alignment = model.Alignment;
    end
    Brillouin = model.Brillouin;
    switch (Brillouin.dimension)
        case 0
        case 1
            %% Extract positions to show in ODT and Fluorescence
            xPos = nanmean(Brillouin.positions.(Brillouin.sdims{2})(:));
            Alignment.position.x = xPos;
            yPos = nanmean(Brillouin.positions.(Brillouin.sdims{1})(:));
            Alignment.position.y = yPos;
        case 2
            %% Extract positions to show in ODT and Fluorescence
            minX = min(Brillouin.positions.x(:));
            maxX = max(Brillouin.positions.x(:));
            xPos = [minX, maxX, maxX, minX, minX];
            Alignment.position.x = xPos;
            minY = min(Brillouin.positions.y(:));
            maxY = max(Brillouin.positions.y(:));
            yPos = [minY, minY, maxY, maxY, minY];
            Alignment.position.y = yPos;
        case 3
    end
    model.Alignment = Alignment;
end