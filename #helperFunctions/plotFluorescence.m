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
                
                % In case we have a Brillouin measurement, also export the
                % ROI of Brillouin only
                BMrepetitions = file.getRepetitions('Brillouin');
                for jj = 1:length(BMrepetitions)
                    BMfilename = parameters.filename;
                    if length(BMrepetitions) > 1
                        BMfilename = [BMfilename '_rep' num2str(BMrepetitions{jj})]; %#ok<AGROW>
                    end

                    BMresults = load([parameters.path filesep 'EvalData' filesep BMfilename '.mat']);

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
                        scaleCalibration.micrometerToPixX(1) scaleCalibration.micrometerToPixX(2) 0; ...
                        scaleCalibration.micrometerToPixY(1) scaleCalibration.micrometerToPixY(2) 0; ...
                        0 0 n; ...
                    ]/n);
                    image_warped = imwarp(image, tform);
                    
                    x = linspace(min(micrometerX, [], 'all'), max(micrometerX, [], 'all'), round(size(image_warped, 2)));
                    y = linspace(min(micrometerY, [], 'all'), max(micrometerY, [], 'all'), round(size(image_warped, 1)));
                    
                    imagePath = [parameters.path filesep 'Plots' filesep parameters.filename ...
                        '_FLrep' num2str(FLrepetitions{ii}) sprintf('_channel%s_BMrep', channel) num2str(BMrepetitions{jj}) '_fullFOV.png'];
                    
                    % Export full field-of-view
                    imwrite(flipud(image_warped), map, imagePath);
                    
                    % Export Brillouin ROI only
                    [~, indX_min] = min(abs(x - min(BMresults.results.parameters.positions.X, [], 'all')));
                    [~, indX_max] = min(abs(x - max(BMresults.results.parameters.positions.X, [], 'all')));
                    [~, indY_min] = min(abs(y - min(BMresults.results.parameters.positions.Y, [], 'all')));
                    [~, indY_max] = min(abs(y - max(BMresults.results.parameters.positions.Y, [], 'all')));
                    
                    %% Interpolate the image to have the correct pixel count
                    [X, Y] = meshgrid(x, y);
                    % find the minimum resolution
                    resolution = min( ... % [pix/µm]
                        abs((indX_max-indX_min) / (x(indX_max) - x(indX_min))), ...
                        abs((indY_max-indY_min) / (y(indY_max) - y(indY_min))) );
                    % create position vectors with the respective
                    % resolution
                    x_new = linspace(x(indX_min), x(indX_max), round((x(indX_max) - x(indX_min)) * resolution));
                    y_new = linspace(y(indY_min), y(indY_max), round((y(indY_max) - y(indY_min)) * resolution));
                    [Xq, Yq] = meshgrid(x_new, y_new);
                    image_warped_BM = uint8(zeros(length(y_new), length(x_new), size(image_warped, 3)));
                    for dd = 1:size(image_warped, 3)
                        image_warped_BM(:,:,dd) = uint8(interp2(X, Y, double(image_warped(:,:,dd)), Xq, Yq));
                    end

                    imagePath = [parameters.path filesep 'Plots' filesep parameters.filename ...
                        '_FLrep' num2str(FLrepetitions{ii}) sprintf('_channel%s_BMrep', channel) num2str(BMrepetitions{jj}) '.png'];
                    imwrite(flipud(image_warped_BM), map, imagePath);
                end
            end
        end
        h5bmclose(file);
    catch
    end
end