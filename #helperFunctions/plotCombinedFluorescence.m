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
    
    FLrepetitions = file.getRepetitions('Fluorescence');
    for kk = 1:length(parameters.Fluorescence.combinations)
        combination = parameters.Fluorescence.combinations{kk};
        for jj = 1:length(FLrepetitions)
            channels = file.readPayloadData('Fluorescence', FLrepetitions{jj}, 'memberNames');
            if isempty(channels)
                continue;
            end
            %% Check if we have an image for every requested channel
            exportPlot = zeros(1, length(combination));
            for channelInd = 1:length(combination)
                if strcmp(combination(channelInd), '_')
                    exportPlot(channelInd) = 1;
                end
            end

            % Load one image to get the size
            img = file.readPayloadData('Fluorescence', FLrepetitions{jj}, 'data', channels{1});
            fluorescence = zeros(size(img, 1), size(img, 2), 3);
            for ll = 1:length(channels)
                channel = file.readPayloadData('Fluorescence', FLrepetitions{jj}, 'channel', channels{ll});
                % If it is a brightfield image, skip it
                if strcmpi('brightfield', channel)
                    continue;
                end

                % Check if the channel is contained in the requested
                % combinations
                ind = strfind(combination, lower(channel(1)));
                backgroundInd = strfind('rgb', lower(channel(1)));
                if ~isempty(ind)
                    exportPlot(ind) = 1;
                    img = file.readPayloadData('Fluorescence', FLrepetitions{jj}, 'data', channels{ll});
                    
                    % If we loaded a background, subtract it
                    if exist('background', 'var')
                        img = uint8(img) - background(:, :, backgroundInd);
                    % If we didn't subtract a background image, we apply a
                    % medianfilter to remove salt and pepper noise for
                    % pixels whose value is more than 3 sigma different
                    % than the median filtered value
                    else
                        img_filtered = medfilt2(img);
                        tmp = abs(img - img_filtered) > 3*std(img, 0, 'all');
                        img(tmp) = img_filtered(tmp);
                    end

                    img = img - mean2(img(end-15:end-5, 5:15));
                    img = conv2(img, fspecial('disk', 2), 'same');
                    pmap = imgaussfilt(img, 300);
                    img = img - pmap;
                    img = wiener2(img, [5 5]);
                    fluorescence(:, :, ind) = img;
                end
            end
            
            if isempty(find(~exportPlot, 1))
                %% Setting the contrast of the different channels
                if isfield(parameters.Fluorescence, 'contrast')
                    % Scale all channels by the same factor
                    if strcmp(parameters.Fluorescence.contrast, 'equal')
                        fluorescence = uint8(fluorescence ./ max(fluorescence(:)) * 255);
                    % Scale each channel to max contrast
                    elseif strcmp(parameters.Fluorescence.contrast, 'max')
                        for ch = 1:size(fluorescence, 3)
                            fluorescence(:, :, ch) = fluorescence(:, :, ch) ./ max(fluorescence(:, :, ch), [], 'all') * 255;
                        end
                    end
                else
                    for ch = 1:size(fluorescence, 3)
                        fluorescence(:, :, ch) = fluorescence(:, :, ch) ./ max(fluorescence(:, :, ch), [], 'all') * 255;
                    end
                end

                imwrite(flipud(uint8(fluorescence)), [parameters.path filesep 'Plots' filesep 'Bare' filesep ...
                    parameters.filename '_FLrep' num2str(FLrepetitions{jj}) '_fluorescenceCombined_' combination '.png'], 'BitDepth', 8);

                scaleCalibration = file.getScaleCalibration('Fluorescence', FLrepetitions{jj});

                ROI = file.readPayloadData('Fluorescence', FLrepetitions{jj}, 'ROI', channels{1});

                [pixX, pixY] = meshgrid( ...
                    (0:(ROI.width_physical - 1)) + ROI.left, ...
                    (0:(ROI.height_physical - 1)) + ROI.bottom);

                pixX = pixX - scaleCalibration.origin(1);
                pixY = pixY - scaleCalibration.origin(2);

                micrometerX = pixX .* scaleCalibration.pixToMicrometerX(1) + pixY .* scaleCalibration.pixToMicrometerY(1) + ...
                    scaleCalibration.positionStage(1);
                micrometerY = pixX .* scaleCalibration.pixToMicrometerX(2) + pixY .* scaleCalibration.pixToMicrometerY(2) + ...
                    scaleCalibration.positionStage(2);

                %% Warp images for imagesc using affine transform
                n = norm([scaleCalibration.micrometerToPixX(1) scaleCalibration.micrometerToPixX(2)]);
                tform = affine2d([ ...
                    -1*scaleCalibration.micrometerToPixY(2) scaleCalibration.micrometerToPixX(2) 0; ...    
                    scaleCalibration.micrometerToPixY(1) -1*scaleCalibration.micrometerToPixX(1) 0; ...
                    0 0 n; ...
                ]/n);
                image_warped = imwarp(fluorescence, tform, 'FillValues', NaN);

                % Calculate the grid of the image
                x = linspace(min(micrometerX, [], 'all'), max(micrometerX, [], 'all'), round(size(image_warped, 2)));
                y = linspace(min(micrometerY, [], 'all'), max(micrometerY, [], 'all'), round(size(image_warped, 1)));

                [X, Y] = meshgrid(x, y);

                % Find the minimum resolution
                resolution = min( ... % [pix/µm]
                    sqrt(sum(scaleCalibration.micrometerToPixX.^2)), ...
                    sqrt(sum(scaleCalibration.micrometerToPixY.^2)) );

                %% Export full field-of-view
                imagePath = [parameters.path filesep 'Plots' filesep 'Bare' filesep parameters.filename ...
                    '_FLrep' num2str(FLrepetitions{jj}) ...
                    sprintf('_fluorescenceCombined_%s_aligned.png', combination)];

                imwrite(flipud(uint8(image_warped)), imagePath, 'BitDepth', 8, 'Alpha', flipud(double(max(~isnan(image_warped), [], 3))));
                
                % In case we have a Brillouin measurement, also export the
                % ROI of Brillouin only
                BMrepetitions = file.getRepetitions('Brillouin');
                for mm = 1:length(BMrepetitions)
                    try
                        BMfilename = parameters.filename;
                        if length(BMrepetitions) > 1
                            BMfilename = [BMfilename '_rep' num2str(BMrepetitions{mm})]; %#ok<AGROW>
                        end

                        BMresults = load([parameters.path filesep 'EvalData' filesep BMfilename '.mat']);

                        %% Only export the Brillouin field-of-view

                        % Create position vectors with the respective resolution
                        x_min = min(BMresults.results.parameters.positions.X, [], 'all');
                        x_max = max(BMresults.results.parameters.positions.X, [], 'all');
                        x_new = linspace(x_min, x_max, round((x_max - x_min) * resolution));

                        y_min = min(BMresults.results.parameters.positions.Y, [], 'all');
                        y_max = max(BMresults.results.parameters.positions.Y, [], 'all');
                        y_new = linspace(y_min, y_max, round((y_max - y_min) * resolution));

                        [Xq, Yq] = meshgrid(x_new, y_new);

                        % Interpolate the image
                        image_warped_BM = zeros(length(y_new), length(x_new), size(image_warped, 3));
                        for dd = 1:size(image_warped, 3)
                            image_warped_BM(:,:,dd) = interp2(X, Y, double(image_warped(:,:,dd)), Xq, Yq);
                        end

                        imagePath = [parameters.path filesep 'Plots' filesep 'Bare' filesep parameters.filename ...
                            '_FLrep' num2str(FLrepetitions{jj}) ...
                            sprintf('_fluorescenceCombined_%s_BMrep', combination) num2str(BMrepetitions{mm}) '.png'];
                        imwrite(flipud(uint8(image_warped_BM)), imagePath, 'BitDepth', 8, 'Alpha', flipud(double(max(~isnan(image_warped_BM), [], 3))));
                    catch
                    end
                end
            end
        end
    end
end