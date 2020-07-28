function plotBrillouinModulusDeviation(parameters)

    try
        %% construct filename
        filePath = [parameters.path filesep 'RawData' filesep parameters.filename '.h5'];
        %% Open file for reading
        file = h5bmread(filePath);
        
        %% Loop over all repetitions
        ODTrepetitions = file.getRepetitions('ODT');
        BMrepetitions = file.getRepetitions('Brillouin');
        
        %% Loop over all combinations of BM and ODT repetitions
        for ll = 1:length(ODTrepetitions)
            for jj = 1:length(BMrepetitions)
                try
                    %% Load alignment and modulus
                    alignmentFilename = parameters.filename;
                    if length(BMrepetitions) > 1
                        alignmentFilename = [alignmentFilename '_BMrep' num2str(BMrepetitions{jj})]; %#ok<AGROW>
                    end
                    if length(ODTrepetitions) > 1
                        alignmentFilename = [alignmentFilename '_ODTrep' num2str(ODTrepetitions{ll})]; %#ok<AGROW>
                    end
                    alignmentPath = [parameters.path filesep 'EvalData' filesep alignmentFilename '_modulus.mat'];
                    alignment = load(alignmentPath);
            
                    %% plot the measurement results
                    BMfilename = parameters.filename;
                    if length(BMrepetitions) > 1
                        BMfilename = [BMfilename '_rep' num2str(BMrepetitions{jj})]; %#ok<AGROW>
                    end

                    BMresults = load([parameters.path filesep 'EvalData' filesep BMfilename '.mat']);
                    
                    validity = BMresults.results.results.validity;
                    validityLevel = BMresults.results.results.peaksBrillouin_dev./BMresults.results.results.peaksBrillouin_int;

                    dims = {'X', 'Y', 'Z'};
                    for kk = 1:length(dims)
                        pos.([dims{kk} '_zm']) = ...
                            BMresults.results.parameters.positions.(dims{kk});
                        pos.([dims{kk} '_zm']) = squeeze(pos.([dims{kk} '_zm']));
                    end
                    pos.X_zm = pos.X_zm + alignment.Alignment.dx;
                    pos.Y_zm = pos.Y_zm + alignment.Alignment.dy;
                    pos.Z_zm = pos.Z_zm + alignment.Alignment.dz;

                    %% Calculate the FOV for the RI measurements
                    nrPix = 342;%size(BMresults.results.results.RISection, 1);
                    res = 0.2530;
                    pos.X_zm_RI = ((1:nrPix) - nrPix/2) * res;
                    pos.Y_zm_RI = pos.X_zm_RI;

                    names = {};
                    try
                        masks = BMresults.results.results.masks;
                    catch
                        masks = {};
                    end
    
                    %% Plot longitudinal modulus without RI
                    M = 1e-9*alignment.modulus.M;
                    M_woRI = 1e-9*alignment.modulus.M_woRI;
                    
                    % filter invalid values
                    M(~validity) = NaN;
                    M(validityLevel > parameters.Modulus.validity) = NaN;
                    
                    M_woRI(~validity) = NaN;
                    M_woRI(validityLevel > parameters.Modulus.validity) = NaN;
                    
                    if size(M, 5) >= parameters.Modulus.peakNumber && isfield(parameters.Modulus, 'peakNumber')
                        M = M(:,:,:,:,parameters.Modulus.peakNumber);
                    else
                        M = M(:,:,:,:,1);
                    end
                    if size(M_woRI, 5) >= parameters.Modulus.peakNumber && isfield(parameters.Modulus, 'peakNumber')
                        M_woRI = M_woRI(:,:,:,:,parameters.Modulus.peakNumber);
                    else
                        M_woRI = M_woRI(:,:,:,:,1);
                    end

                    M_woRI_norm = 1e2*(M - M_woRI) / min(M(:));
                    
                    M_woRI_norm_mean = nanmean(M_woRI_norm, 4);
                    
                    plotData(parameters.path, M_woRI_norm_mean , pos, parameters.Modulus.M_woRI_norm.cax, ...
                        '$\Delta M$ [\%]', [alignmentFilename '_modulusDeviation'], 0, masks, names);
                    
                catch
                end
            end
        end
        
        h5bmclose(file);
    catch
    end
    
    function plotData(plotPath, data, pos, cax, colorbarTitle, filename, showOutline, masks, names)
        
        
        %% plot results
        figure;
        imagesc(pos.X_zm(1,:), pos.Y_zm(:,1), data, 'AlphaData', ~isnan(data));
        hold on;
        if showOutline
            for mm = 1:length(names)
                name = names{mm};
                field = findField(masks, 'name', name);
                colorMask = cat(3, ...
                    masks.(field).color(1)*ones(size(data)), ...
                    masks.(field).color(2)*ones(size(data)), ...
                    masks.(field).color(3)*ones(size(data))...
                );
                outline = bwperim(masks.(field).mask);

                imagesc(pos.X_zm(1,:), pos.Y_zm(:,1), colorMask, 'AlphaData', masks.(field).transparency*double(outline));
            end
        end
        axis equal;
        axis([min(pos.X_zm(:)), max(pos.X_zm(:)), min(pos.Y_zm(:)), max(pos.Y_zm(:))]);
        caxis(cax);
        cb = colorbar;
        %% Check if the coolwarm colormap function exists, if not use jet
        if exist('coolwarm', 'file') == 2
            map = coolwarm(2^8);
        else
            map = jet(2^8);
        end
        colormap(map);
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
            'figpos', [1 1 10 6], ...
            'axepos', [0.10 0.17 0.7 0.74], ...
            'colpos', [0.82 0.17 0.059 0.74] ...
        );
        prepare_fig([plotPath filesep 'Plots' filesep 'WithAxis' filesep filename], ...
            'output', 'png', 'style', 'article', 'layout', layout);
        
        % Also export the plot with the ODT FOV limits
        axis([min(pos.X_zm_RI(:)), max(pos.X_zm_RI(:)), min(pos.Y_zm_RI(:)), max(pos.Y_zm_RI(:))]);
        layout = struct( ...
            'figpos', [1 1 8 6], ...
            'axepos', [0.10 0.17 0.7 0.74], ...
            'colpos', [0.8 0.17 0.059 0.74] ...
        );
        prepare_fig([plotPath filesep 'Plots' filesep 'WithAxis' filesep filename '_fullFOV'], ...
            'output', {'png'}, 'style', 'article', 'command', {'close'}, 'layout', layout);

        %% print image without axis and colorbar

        pixelValues = data;
        pixelValues = rot90(pixelValues,2);
        pixelValues = fliplr(pixelValues);

        % set caxis for png image
        pixelValues(pixelValues < cax(1)) = cax(1);
        pixelValues(pixelValues > cax(2)) = cax(2);

        % transparency matrix
        transparent = double(~isnan(pixelValues));

        % scale image values to 'bitdepth' bit
        pixelValues = pixelValues - cax(1);
        pixelValues = round(2^8*pixelValues/(cax(2)-cax(1)));

        RGB = ind2rgb(pixelValues, map);
        
        if showOutline
            for mm = 1:length(names)
                name = names{mm};
                field = findField(masks, 'name', name);
                outline = rot90(bwperim(masks.(field).mask),2);
                outline = fliplr(outline);
        
                fg.A = masks.(field).transparency*outline;
                fg.R = masks.(field).color(1)*ones(size(data)).*outline;
                fg.G = masks.(field).color(2)*ones(size(data)).*outline;
                fg.B = masks.(field).color(3)*ones(size(data)).*outline;
        
                bg.A = transparent;
                bg.R = RGB(:,:,1);
                bg.G = RGB(:,:,2);
                bg.B = RGB(:,:,3);
                
                r.A = 1 - (1 - fg.A) .* (1 - bg.A);
                r.R = fg.R .* fg.A ./ r.A + bg.R .* bg.A .* (1 - fg.A) ./ r.A;
                r.G = fg.G .* fg.A ./ r.A + bg.G .* bg.A .* (1 - fg.A) ./ r.A;
                r.B = fg.B .* fg.A ./ r.A + bg.B .* bg.A .* (1 - fg.A) ./ r.A;
                RGB = cat(3, r.R, r.G, r.B);
                RGB(isnan(RGB)) = 1;
                transparent = r.A;
            end
        end
    
        imwrite(RGB, [plotPath filesep 'Plots' filesep 'Bare' filesep filename '_bare.png'], 'BitDepth', 8, 'Alpha', transparent);
        
        %% Calculate an image with the same FOV as the ODT result
        [X, Y] = meshgrid(pos.X_zm(1,:), pos.Y_zm(:,1));
        xmin = min(pos.X_zm_RI);
        xmax = max(pos.X_zm_RI);
        nrPosX = round((xmax - xmin)/abs(pos.X_zm(1,1) - pos.X_zm(1,2)));
        x_new = linspace(xmin, xmax, nrPosX);
        ymin = min(pos.X_zm_RI);
        ymax = max(pos.X_zm_RI);
        nrPosY = round((ymax - ymin)/abs(pos.Y_zm(1,1) - pos.Y_zm(2,1)));
        y_new = linspace(xmin, xmax, nrPosY);
        [X_RI, Y_RI] = meshgrid(x_new, y_new);
        
        RGB_fullFOV(:,:,1) = interp2(X, Y, RGB(:,:,1), X_RI, Y_RI, 'nearest');
        RGB_fullFOV(:,:,2) = interp2(X, Y, RGB(:,:,2), X_RI, Y_RI, 'nearest');
        RGB_fullFOV(:,:,3) = interp2(X, Y, RGB(:,:,3), X_RI, Y_RI, 'nearest');
        
        transparent = double(~isnan(RGB_fullFOV(:,:,1)));

        imwrite(RGB_fullFOV, [plotPath filesep 'Plots' filesep 'Bare' filesep filename '_fullFOV_bare.png'], 'BitDepth', 8, 'Alpha', transparent);
    end
end