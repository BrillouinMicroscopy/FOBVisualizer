function callbacks = Fluorescence(model, view)
%% DATA Controller

    %% general panel
    set(view.Fluorescence.repetition, 'ValueChangedFcn', {@selectRepetition, model});
    set(view.Fluorescence.channels, 'ValueChangedFcn', {@selectChannel, model});

    callbacks = struct( ...
        'loadRepetition', @()loadRepetition(model, model.Fluorescence.repetition, model.Fluorescence.channel) ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    items = get(src, 'Items');
    repetition.index = find(strcmp(items, val));
    repetition.name = model.Fluorescence.repetitions{repetition.index};
    loadRepetition(model, repetition, model.Fluorescence.channel);
end

function selectChannel(src, ~, model)
    val = get(src, 'Value');
    items = get(src, 'Items');
    channel = find(strcmp(items, val));
    loadRepetition(model, model.Fluorescence.repetition, channel);
end

function loadRepetition(model, repetition, channel)
    Fluorescence = model.Fluorescence;
    
    Fluorescence.repetition = repetition;
    Fluorescence.channel = channel;
    
    if ~isempty(Fluorescence.repetitions)
        try

            Fluorescence.channelNames = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'memberNames');
            if (Fluorescence.channel > length(Fluorescence.channelNames))
                Fluorescence.channel = 1;
            end

            Fluorescence.channelName = Fluorescence.channelNames{Fluorescence.channel};

            Fluorescence.type = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'channel', Fluorescence.channelName);

            data = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'data', Fluorescence.channelName);
            data = medfilt1(data, 3);
            Fluorescence.date = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'date', Fluorescence.channelName);

            try
                scaleCalibration = model.file.getScaleCalibration('Fluorescence', Fluorescence.repetition.name);
            
                Fluorescence.ROI = model.file.readPayloadData('Fluorescence', Fluorescence.repetition.name, 'ROI', Fluorescence.channelName);
                
                [pixX, pixY] = meshgrid( ...
                    (0:(Fluorescence.ROI.width_physical - 1)) + Fluorescence.ROI.left, ...
                    (0:(Fluorescence.ROI.height_physical - 1)) + Fluorescence.ROI.bottom);
                
                pixX = pixX - scaleCalibration.origin(1);
                pixY = pixY - scaleCalibration.origin(2);
                
                micrometerX = pixX .* scaleCalibration.pixToMicrometerX(1) + pixY .* scaleCalibration.pixToMicrometerY(1) + ...
                    scaleCalibration.positionStage(1);
                micrometerY = pixX .* scaleCalibration.pixToMicrometerX(2) + pixY .* scaleCalibration.pixToMicrometerY(2) + ...
                    scaleCalibration.positionStage(2);
                
                %% Warp images for imagesc using affine transform
                % See FV_View\Fluorescence.m#L91 for why the hell this is
                % necessary.
                x = linspace(min(micrometerX, [], 'all'), max(micrometerX, [], 'all'), round(size(micrometerX, 2)));
                y = linspace(min(micrometerY, [], 'all'), max(micrometerY, [], 'all'), round(size(micrometerY, 1)));
                
                n = norm([scaleCalibration.micrometerToPixX(1) scaleCalibration.micrometerToPixX(2)]);
                tform = affine2d([ ...
                    scaleCalibration.micrometerToPixX(1) scaleCalibration.micrometerToPixX(2) 0; ...
                    scaleCalibration.micrometerToPixY(1) scaleCalibration.micrometerToPixY(2) 0; ...
                    0 0 n; ...
                ]/n);
                data = imwarp(data, tform);
            catch
                x = 4.8*(1:size(data, 1))/57;
                x = x - nanmean(x(:));
                y = 4.8*(1:size(data, 2))/57;
                y = y - nanmean(y(:));
            end
            Fluorescence.data = data;

            Fluorescence.positions.x = x;
            Fluorescence.positions.y = y;
        catch
            Fluorescence.data = NaN;
            Fluorescence.date = '';
            Fluorescence.positions = struct( ...
                'x', [], ...
                'y', [], ...
                'z', [] ...
            );
        end
    end
    
    model.Fluorescence = Fluorescence;
end