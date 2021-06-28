function plotRefractiveIndex(parameters)
    try
        %% construct filename
        filePath = [parameters.path filesep 'RawData' filesep parameters.filename '.h5'];
        %% Open file for reading
        file = FV_Utils.HDF5Storage.h5bmread(filePath);
        
        %% Loop over all repetitions
        ODTrepetitions = file.getRepetitions('ODT');
        BMrepetitions = file.getRepetitions('Brillouin');
        
        BMZres = 2;
        
        %% Loop over all combinations of BM and ODT repetitions
        for jj = 1:length(ODTrepetitions)
                    
            ODTfilename = parameters.filename;
            if length(ODTrepetitions) > 1
                ODTfilename = [ODTfilename '_rep' num2str(ODTrepetitions{jj})]; %#ok<AGROW>
            end
            filepath = [parameters.path filesep 'EvalData' filesep 'Tomogram_Field_' ODTfilename '.mat'];
            ODTResults = load(filepath, 'Reconimg', 'res3', 'res4');
            
            for kk = 1:length(BMrepetitions)
                try
                    %% Load alignment
                    alignmentFilename = parameters.filename;
                    if length(BMrepetitions) > 1
                        alignmentFilename = [alignmentFilename '_BMrep' num2str(BMrepetitions{kk})]; %#ok<AGROW>
                    end
                    if length(ODTrepetitions) > 1
                        alignmentFilename = [alignmentFilename '_ODTrep' num2str(ODTrepetitions{jj})]; %#ok<AGROW>
                    end
                    alignmentPath = [parameters.path filesep 'EvalData' filesep alignmentFilename '_modulus.mat'];
                    alignment = load(alignmentPath);
                    
                    %% Load Brillouin for position
                    BMfilename = parameters.filename;
                    if length(BMrepetitions) > 1
                        BMfilename = [BMfilename '_rep' num2str(BMrepetitions{jj})]; %#ok<AGROW>
                    end

                    BMresults = load([parameters.path filesep 'EvalData' filesep BMfilename '.mat']);
                    
                    pos.Z_zm = BMresults.results.parameters.positions.Z;
                    pos.Z_zm = squeeze(pos.Z_zm);
                    
                    %% Determine the z-position at which to export
                    if ~isfield(parameters.ODT.RI, 'zReference')
                        parameters.ODT.RI.zReference = 'Brillouin';
                    end
                    if ~isfield(parameters.ODT.RI, 'z')
                        parameters.ODT.RI.z = 0;
                    end
                    
                    switch lower(parameters.ODT.RI.zReference)
                        case 'odt'
                            z = parameters.ODT.RI.z;
                        case 'dish'
                            z = alignment.Alignment.z0 + parameters.ODT.RI.z;
                        otherwise % Default is 'brillouin'
                            pos.Z_zm = pos.Z_zm + alignment.Alignment.dz + parameters.ODT.RI.z;
                            z = pos.Z_zm(1,1);
                    end
                    
                    %% Calculate the correct z-plane for ODT
                    indZ = size(ODTResults.Reconimg, 3)/2 - round(z / ODTResults.res4);
                    
                    %% Bring the ODT measurement to the Brillouin resolution
%                     RI_averaged = mean(ODTResults.Reconimg(:, :, (0:round(BMZres/ODTResults.res4)) + indZ - round(BMZres/ODTResults.res4)/2), 3);
%                     RI = conv2(squeeze(RI_averaged), fspecial('disk', 0.7), 'same');
                    
                    %% Use exact RI without averaging
                    RI = ODTResults.Reconimg(:, :, indZ);
                    
                    %%
                    nrPix = size(RI, 1);
                    res = 0.2530;
                    pos.x = ((1:nrPix)-nrPix/2)*res;
                    pos.y = pos.x;

                    %% Plot refractive index
                    plotData(parameters.path, RI, pos, parameters.ODT.RI.cax, '$n$', alignmentFilename);
                catch
                end
            end
            
            % If there are no Brillouin measurements, just export the
            % center RI plane
            if length(BMrepetitions) < 1
                %% Calculate the correct z-plane for ODT
                indZ = size(ODTResults.Reconimg, 3)/2;

                %% Bring the ODT measurement to the Brillouin resolution
%                     RI_averaged = mean(ODTResults.Reconimg(:, :, (0:round(BMZres/ODTResults.res4)) + indZ - round(BMZres/ODTResults.res4)/2), 3);
%                     RI = conv2(squeeze(RI_averaged), fspecial('disk', 0.7), 'same');

                %% Use exact RI without averaging
                RI = ODTResults.Reconimg(:, :, indZ);

                %%
                nrPix = size(RI, 1);
                res = 0.2530;
                pos.x = ((1:nrPix)-nrPix/2)*res;
                pos.y = pos.x;
                
                alignmentFilename = parameters.filename;
                if length(ODTrepetitions) > 1
                    alignmentFilename = [alignmentFilename '_ODTrep' num2str(ODTrepetitions{jj})]; %#ok<AGROW>
                end

                %% Plot refractive index
                plotData(parameters.path, RI, pos, parameters.ODT.RI.cax, '$n$', alignmentFilename);
            end
        end
        h5bmclose(file);
    catch
    end
    
    function plotData(path, data, pos, cax, colorbarTitle, filename)
        
        
        %% plot results
        figure;
        imagesc(pos.x, pos.y, data, 'AlphaData', ~isnan(data));
        hold on;
        axis equal;
        axis([min(pos.x), max(pos.x), min(pos.y), max(pos.y)]);
        caxis(cax);
        colormap(FV_Utils.Colormaps.inferno);
        cb = colorbar;
        title(cb, colorbarTitle, 'interpreter', 'latex');
        view([0 90]);
        box on;
        xlabel('$x$ [$\mu$m]', 'interpreter', 'latex');
        ylabel('$y$ [$\mu$m]', 'interpreter', 'latex');
        zlabel('$z$ [$\mu$m]', 'interpreter', 'latex');
        set(gca, 'xDir', 'normal');
        set(gca, 'yDir', 'normal');
        
        %%
        layout = struct( ...
            'figpos', [1 1 8 6], ...
            'axepos', [0.10 0.17 0.7 0.74], ...
            'colpos', [0.8 0.17 0.059 0.74] ...
        );
        prepare_fig([path filesep 'Plots' filesep 'WithAxis' filesep filename '_RefractiveIndex'], ...
            'output', {'png'}, 'style', 'article', 'command', {'close'}, 'layout', layout);

        %% print image without axis and colorbar

        pixelValues = data;
        pixelValues = rot90(pixelValues,2);
        pixelValues = fliplr(pixelValues);

        % set caxis for png image
        pixelValues(pixelValues < cax(1)) = cax(1);
        pixelValues(pixelValues > cax(2)) = cax(2);

        % scale image values to 'bitdepth' bit
        pixelValues = pixelValues - cax(1);
        pixelValues = round(2^8*pixelValues/(cax(2)-cax(1)));

        map = FV_Utils.Colormaps.inferno(2^8);
        RGB = ind2rgb(pixelValues, map);
    
        imwrite(RGB,[path filesep 'Plots' filesep 'Bare' filesep filename '_RefractiveIndex.png'], 'BitDepth', 8);

    end
end