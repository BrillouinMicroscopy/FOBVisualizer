function callbacks = ODT(model, view)
%% DATA Controller

    %% general panel
    set(view.ODT.repetition, 'Callback', {@selectRepetition, model, view});
    set(view.ODT.maxProj, 'Callback', {@toggleMaxProj, model, view});
    
    set(view.ODT.zDepth, 'StateChangedCallback', {@selectZDepth, model});

    callbacks = struct( ...
        'loadRepetition', @()loadRepetition(model, view, model.ODT.repetition) ...
    );
end

function selectRepetition(src, ~, model, view)
    val = get(src, 'Value');
    repetition.index = val;
    repetition.name = model.ODT.repetitions{val};
    
    loadRepetition(model, view, repetition);

    % Load the alignment from file
    model.controllers.data.loadAlignmentData();
end

function loadRepetition(model, view, repetition)
    ODT = model.ODT;
    ODT.repetition = repetition;
    
    if ~isempty(ODT.repetitions)
        try
            [~, name, ~] = fileparts(model.filename);
            if length(ODT.repetitions) > 1
                name = [name '_rep' num2str(ODT.repetition.name)];
            end
            filepath = [model.filepath '..' filesep 'EvalData' filesep 'Tomogram_Field_' name '.mat'];
            ODT.data = load(filepath, 'Reconimg', 'res3', 'res4');

            ODT.date = model.file.readPayloadData('ODT', ODT.repetition.name, 'date', 0);
            
            ZP4 = round(size(ODT.data.Reconimg,1));
            x = ((1:ZP4)-ZP4/2)*ODT.data.res3;
            y = x;
            
            ZP5 = round(size(ODT.data.Reconimg,3));
            z = fliplr(((1:ZP5)-ZP5/2)*ODT.data.res4);
            
            [X, Y, Z] = meshgrid(x, y, z);
            
            ODT.positions.x = X;
            ODT.positions.y = Y;
            ODT.positions.z = Z;
            
            minZ = round(min(Z(:)));
            maxZ = round(max(Z(:)));
            spacingZ = round((maxZ - minZ) / 15);
            set(view.ODT.zDepth, 'Maximum', maxZ);
            set(view.ODT.zDepth, 'Minimum', minZ);
            set(view.ODT.zDepth, 'MajorTickSpacing', spacingZ);
            set(view.ODT.zDepth, 'MinorTickSpacing', spacingZ);
            
        catch
            ODT.data = NaN;
            ODT.date = '';
        end
    end
    
    model.ODT = ODT;
    model.controllers.modulus.calculateModulus();
end

function toggleMaxProj(~, ~, model, view)
    model.ODT.maxProj = get(view.ODT.maxProj, 'Value');
end

function selectZDepth(src, ~, model)
    model.ODT.zDepth = get(src, 'Value');
end