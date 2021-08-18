function callbacks = ODT(model, view)
%% DATA Controller

    %% general panel
    set(view.ODT.repetition, 'ValueChangedFcn', {@selectRepetition, model, view});
    set(view.ODT.maxProj, 'ValueChangedFcn', {@toggleMaxProj, model, view});
    
    set(view.ODT.zDepth, 'ValueChangedFcn', {@selectZDepth, model});

    callbacks = struct( ...
        'loadRepetition', @()loadRepetition(model, view, model.ODT.repetition) ...
    );
end

function selectRepetition(src, ~, model, view)
    val = get(src, 'Value');
    items = get(src, 'Items');
    repetition.index = find(strcmp(items, val));
    repetition.name = model.ODT.repetitions{repetition.index};
    
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
            data = load(filepath, 'Reconimg', 'res3', 'res4');

            ODT.date = model.file.readPayloadData('ODT', ODT.repetition.name, 'date', 0);
            
            try
                scaleCalibration = model.file.getScaleCalibration('ODT', ODT.repetition.name);
            
                ODT.ROI = model.file.readPayloadData('ODT', ODT.repetition.name, 'ROI', 0);
                
                %% Warp images for imagesc using affine transform
                % See FV_View\Fluorescence.m#L91 for why the hell this is
                % necessary.
                n = norm([scaleCalibration.micrometerToPixX(1) scaleCalibration.micrometerToPixX(2)]);
                tform = affine2d([ ...
                    scaleCalibration.micrometerToPixX(1) scaleCalibration.micrometerToPixX(2) 0; ...
                    scaleCalibration.micrometerToPixY(1) scaleCalibration.micrometerToPixY(2) 0; ...
                    0 0 n; ...
                ]/n);

                data.Reconimg = imwarp(data.Reconimg, tform);
            catch
            end
            ODT.data = data;
            
            ZP4 = round(size(data.Reconimg,1));
            x = ((1:ZP4)-ZP4/2)*data.res3;
            y = x;

            ZP5 = round(size(data.Reconimg,3));
            z = fliplr(((1:ZP5)-ZP5/2)*data.res4);

            [X, Y, Z] = meshgrid(x, y, z);
            ODT.positions.x = X;
            ODT.positions.y = Y;
            ODT.positions.z = Z;
            
            minZ = round(min(Z(:)));
            maxZ = round(max(Z(:)));
            spacingZ = round((maxZ - minZ) / 15);
            set(view.ODT.zDepth, 'Limits', [minZ maxZ]);
            set(view.ODT.zDepth, 'MajorTicks', spacingZ * linspace(round(minZ/spacingZ), round(maxZ/spacingZ), 15));
            
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