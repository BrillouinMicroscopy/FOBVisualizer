function plotCombinedFluorescence(parameters)
    
    %% Try to load the background correction image
    background = uint8(zeros(1024, 1024, 3));
    if isfield(parameters.Fluorescence, 'backgroundFile')
        try
            filePath = [parameters.path filesep 'RawData' filesep parameters.Fluorescence.backgroundFile '.h5'];
            %% Open file for reading
            file = h5bmread(filePath);
            
            channels = file.readPayloadData('Fluorescence', 0, 'memberNames');
            for ll = 1:length(channels)
                channel = file.readPayloadData('Fluorescence', 0, 'channel', channels{ll});
                % If it is a brightfield image, skip it
                if strcmpi('brightfield', channel)
                    continue;
                end
                
                ind = strfind('rgb', lower(channel(1)));
                if ~isempty(ind)
                    background(:, :, ind) = uint8(file.readPayloadData('Fluorescence', 0, 'data', channels{ll}));
                end
            end
            
            h5bmclose(file);
        catch
        end
    end

    %% construct filename
    filePath = [parameters.path filesep 'RawData' filesep parameters.filename '.h5'];
    %% Open file for reading
    file = h5bmread(filePath);
    
    FluoRepetitions = file.getRepetitions('Fluorescence');
    for kk = 1:length(parameters.Fluorescence.combinations)
        combination = parameters.Fluorescence.combinations{kk};
        for jj = 1:length(FluoRepetitions)
            fluorescence = uint8(zeros(1024, 1024, 3));
            channels = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'memberNames');
            for ll = 1:length(channels)
                channel = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'channel', channels{ll});
                % If it is a brightfield image, skip it
                if strcmpi('brightfield', channel)
                    continue;
                end

                % Check if the channel is contained in the requested
                % combinations
                ind = strfind(combination, lower(channel(1)));
                backgroundInd = strfind('rgb', lower(channel(1)));
                if ~isempty(ind)
                    img = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'data', channels{ll});

                    temp = uint8(img) - background(:, :, backgroundInd);

                    temp = temp - mean2(temp(end-15:end-5, 5:15));
                    temp = conv2(temp, fspecial('disk', 2), 'same');
                    pmap = imgaussfilt(temp, 300);
                    temp = temp - pmap;
                    temp = wiener2(temp, [5 5]);
                    fluorescence(:, :, ind) = uint8(temp ./ max(temp(:)) * 375);
                end
            end

            fluorescence = flipud(fluorescence);
            imwrite(fluorescence, [parameters.path filesep 'Plots' filesep 'Bare' filesep ...
                parameters.filename '_FLrep' num2str(FluoRepetitions{jj}) '_fluorescenceCombined_' combination '.png'], 'BitDepth', 8);
        end
    end
end