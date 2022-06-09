function plotFluorescence(parameters)
    try
        %% construct filename
        filePath = [parameters.path filesep 'RawData' filesep parameters.filename '.h5'];
        %% Open file for reading
        file = FV_Utils.HDF5Storage.h5bmread(filePath);
        
        %% Loop over all repetitions
        FLrepetitions = file.getRepetitions('Fluorescence');
        for ii = 1:length(FLrepetitions)
            %% Loop over all acquired images
            imageNumbers = file.readPayloadData('Fluorescence', FLrepetitions{ii}, 'memberNames');
            for kk = 1:length(imageNumbers)
                channel = file.readPayloadData('Fluorescence', FLrepetitions{ii}, 'channel', imageNumbers{kk});
                % Capitalize the first letter
                channel = [upper(channel(1)) channel(2:end)];
                image = file.readPayloadData('Fluorescence', FLrepetitions{ii}, 'data', imageNumbers{kk});
                %% Construct image path
                imagePath = [parameters.path filesep 'Plots' filesep parameters.filename ...
                    '_FLrep' num2str(FLrepetitions{ii}) sprintf('_channel%s', channel) '.png'];
                switch (channel)
                    case 'Brightfield'
                        nrValues = 256;
                        tmp = image - min(image(:));
                        image = nrValues * tmp ./ max(tmp(:));
                        map = gray(nrValues);
                    case 'Green'
                        nrValues = 256;
                        map = zeros(nrValues, 3);
                        map(:,2) = linspace(0, 1, nrValues);
                    case 'Red'
                        nrValues = 256;
                        map = zeros(nrValues, 3);
                        map(:,1) = linspace(0, 1, nrValues);
                    case 'Blue'
                        nrValues = 256;
                        map = zeros(nrValues, 3);
                        map(:,3) = linspace(0, 1, nrValues);
                end
                imwrite(flipud(image), map, imagePath);
                
                scaleCalibration = file.getScaleCalibration('Fluorescence', FLrepetitions{ii});

                ROI = file.readPayloadData('Fluorescence', FLrepetitions{ii}, 'ROI', imageNumbers{kk});

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
                image_warped = imwarp(image, tform, 'FillValues', NaN);
                
                % Calculate the grid of the image
                x = linspace(min(micrometerX, [], 'all'), max(micrometerX, [], 'all'), round(size(image_warped, 2)));
                y = linspace(min(micrometerY, [], 'all'), max(micrometerY, [], 'all'), round(size(image_warped, 1)));

                [X, Y] = meshgrid(x, y);

                % Find the minimum resolution
                resolution = min( ... % [pix/µm]
                    sqrt(sum(scaleCalibration.micrometerToPixX.^2)), ...
                    sqrt(sum(scaleCalibration.micrometerToPixY.^2)));

                %% Export full field-of-view
                imagePath = [parameters.path filesep 'Plots' filesep parameters.filename ...
                    '_FLrep' num2str(FLrepetitions{ii}) sprintf('_channel%s_aligned.png', channel)];

                RGB = ind2rgb(uint8(image_warped), map);
                imwrite(flipud(RGB), imagePath, 'Alpha', flipud(double(~isnan(image_warped))));
                
                %% In case we have a Brillouin measurement, also export the
                % ROI of Brillouin only
                BMrepetitions = file.getRepetitions('Brillouin');
                for jj = 1:length(BMrepetitions)
                    BMfilename = parameters.filename;
                    if length(BMrepetitions) > 1
                        BMfilename = [BMfilename '_rep' num2str(BMrepetitions{jj})]; %#ok<AGROW>
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
                    image_warped_BM = uint8(zeros(length(y_new), length(x_new), size(image_warped, 3)));
                    for dd = 1:size(image_warped, 3)
                        image_warped_BM(:,:,dd) = uint8(interp2(X, Y, double(image_warped(:,:,dd)), Xq, Yq));
                    end

                    imagePath = [parameters.path filesep 'Plots' filesep parameters.filename ...
                        '_FLrep' num2str(FLrepetitions{ii}) sprintf('_channel%s_BMrep', channel) num2str(BMrepetitions{jj}) '.png'];

                    RGB = ind2rgb(uint8(image_warped_BM), map);
                    imwrite(flipud(RGB), imagePath, 'Alpha', flipud(double(~isnan(image_warped_BM))));
                end
            end
        end
        h5bmclose(file);
    catch
    end
end