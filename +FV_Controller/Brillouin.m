function callbacks = Brillouin(model, view)
%% DATA Controller

    %% general panel
    set(view.Brillouin.repetition, 'Callback', {@selectRepetition, model});

    callbacks = struct( ...
        'loadRepetition', @()loadRepetition(model, model.Brillouin.repetition) ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    repetition.index = val;
    repetition.name = model.Brillouin.repetitions{val};
    
    loadRepetition(model, repetition);
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
            
            Brillouin.shift = data.results.results.BrillouinShift_frequency;
            Brillouin.positions.x = data.results.parameters.positions.X;
            Brillouin.positions.y = data.results.parameters.positions.Y;
            Brillouin.positions.z = data.results.parameters.positions.Z;
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
end