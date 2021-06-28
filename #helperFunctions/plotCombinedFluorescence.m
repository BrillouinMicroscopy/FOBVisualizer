function plotCombinedFluorescence(parameters)
    
    %% Try to load the background correction image
    if isfield(parameters.Fluorescence, 'backgroundFile')
        try
            filePath = [parameters.path filesep 'RawData' filesep parameters.Fluorescence.backgroundFile '.h5'];
            if exist(filePath, 'file')
                %% Open file for reading
                file = FV_Utils.HDF5Storage.h5bmread(filePath);

                channels = file.readPayloadData('Fluorescence', 0, 'memberNames');
                for ll = 1:length(channels)
                    channel = file.readPayloadData('Fluorescence', 0, 'channel', channels{ll});
                    % If it is a brightfield image, skip it
                    if strcmpi('brightfield', channel)
                        continue;
                    end

                    ind = strfind('rgb', lower(channel(1)));
                    if ~isempty(ind)
                        background(:, :, ind) = uint8(file.readPayloadData('Fluorescence', 0, 'data', channels{ll})); %#ok<AGROW>
                    end
                end

                h5bmclose(file);
            end
        catch
        end
    end

    %% construct filename
    filePath = [parameters.path filesep 'RawData' filesep parameters.filename '.h5'];
    %% Open file for reading
    file = FV_Utils.HDF5Storage.h5bmread(filePath);
    
    FluoRepetitions = file.getRepetitions('Fluorescence');
    for kk = 1:length(parameters.Fluorescence.combinations)
        combination = parameters.Fluorescence.combinations{kk};
        for jj = 1:length(FluoRepetitions)
            channels = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'memberNames');
            exportPlot = false;
            % Load one image to get the size
            img = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'data', channels{1});
            fluorescence = uint8(zeros(size(img, 1), size(img, 2), 3));
            for ll = 1:length(channels)
                channel = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'channel', channels{ll});
                % If it is a brightfield image, skip it
                if strcmpi('brightfield', channel)
                    continue;
                end
                exportPlot = true;

                % Check if the channel is contained in the requested
                % combinations
                ind = strfind(combination, lower(channel(1)));
                backgroundInd = strfind('rgb', lower(channel(1)));
                if ~isempty(ind)
                    img = file.readPayloadData('Fluorescence', FluoRepetitions{jj}, 'data', channels{ll});
                    
                    % If we loaded a background, subtract it
                    if exist('background', 'var')
                        img = uint8(img) - background(:, :, backgroundInd);
                    end

                    img = img - mean2(img(end-15:end-5, 5:15));
                    img = conv2(img, fspecial('disk', 2), 'same');
                    pmap = imgaussfilt(img, 300);
                    img = img - pmap;
                    img = wiener2(img, [5 5]);
                    fluorescence(:, :, ind) = uint8(img ./ max(img(:)) * 255);
                end
            end
            
            if exportPlot
                fluorescence = flipud(fluorescence);
                imwrite(fluorescence, [parameters.path filesep 'Plots' filesep 'Bare' filesep ...
                    parameters.filename '_FLrep' num2str(FluoRepetitions{jj}) '_fluorescenceCombined_' combination '.png'], 'BitDepth', 8);
            end
        end
    end
end