function plotFluorescence(parameters)
    try
        %% construct filename
        filePath = [parameters.path filesep 'RawData' filesep parameters.filename '.h5'];
        %% Open file for reading
        file = h5bmread(filePath);
        
        %% Loop over all repetitions
        repetitions = file.getRepetitions('Fluorescence');
        for ii = 1:length(repetitions)
            %% Loop over all acquired images
            imageNumbers = file.readPayloadData('Fluorescence', repetitions{ii}, 'memberNames');
            for kk = 1:length(imageNumbers)
                channel = file.readPayloadData('Fluorescence', repetitions{ii}, 'channel', imageNumbers{kk});
                % Capitalize the first letter
                channel = [upper(channel(1)) channel(2:end)];
                image = file.readPayloadData('Fluorescence', repetitions{ii}, 'data', imageNumbers{kk});
                image = flipud(image);
                %% Construct image path
                imagePath = [parameters.path filesep 'Plots' filesep parameters.filename ...
                    sprintf('_FLrep%01d_channel%s', ii-1, channel) '.png'];
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
                imwrite(image, map, imagePath);
            end
        end
        h5bmclose(file);
    catch
    end
end