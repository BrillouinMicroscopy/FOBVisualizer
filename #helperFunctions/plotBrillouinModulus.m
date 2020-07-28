function plotBrillouinModulus(parameters)
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

                    if isfield(BMresults.results.results, 'BrillouinShift_frequency_normalized')
                        BrillouinShift = BMresults.results.results.BrillouinShift_frequency_normalized;
                    else
                        BrillouinShift = BMresults.results.results.BrillouinShift_frequency;
                    end
                    BrillouinIntensity = BMresults.results.results.peaksBrillouin_int;
                    validity = BMresults.results.results.validity;
                    validityLevel = BMresults.results.results.peaksBrillouin_dev./BMresults.results.results.peaksBrillouin_int;
                    
                    % filter invalid values
                    BrillouinShift(~validity) = NaN;
                    BrillouinShift(validityLevel > parameters.BM.validity) = NaN;

                    % average results
                    if size(BrillouinShift, 5) >= parameters.BM.peakNumber && isfield(parameters.BM, 'peakNumber')
                        BrillouinShift = BrillouinShift(:,:,:,:,parameters.BM.peakNumber);
                    else
                        BrillouinShift = BrillouinShift(:,:,:,:,1);
                    end
                    BS_mean = nanmean(BrillouinShift, 4);
                    
                    % filter invalid values
                    BrillouinIntensity(~validity) = NaN;
                    BrillouinIntensity(validityLevel > parameters.BM.validity) = NaN;

                    % average results
                    if size(BrillouinIntensity, 5) >= parameters.BM.peakNumber && isfield(parameters.BM, 'peakNumber')
                        BrillouinIntensity = BrillouinIntensity(:,:,:,:,parameters.BM.peakNumber);
                    else
                        BrillouinIntensity = BrillouinIntensity(:,:,:,:,1);
                    end
                    BI_mean = nanmean(BrillouinIntensity, 4);
                    BI_mean = BI_mean./max(BI_mean(:));
                    
                    M = 1e-9*alignment.modulus.M;

                    % filter invalid values
                    M(~validity) = NaN;
                    M(validityLevel > parameters.Modulus.validity) = NaN;

                    if size(M, 5) >= parameters.Modulus.peakNumber && isfield(parameters.Modulus, 'peakNumber')
                        M = M(:,:,:,:,parameters.Modulus.peakNumber);
                    else
                        M = M(:,:,:,:,1);
                    end
                    M_mean = nanmean(M, 4);
                    
                    % filter invalid values
                    Rho = 1e-3*alignment.density.rho;
                    Rho(~validity) = NaN;
                    Rho(validityLevel > parameters.Modulus.validity) = NaN;

                    Rho_mean = nanmean(Rho, 4);

                    %% Calculate zero mean positions
                    dims = {'X', 'Y', 'Z'};
                    dimslabel = {'x', 'y', 'z'};
                    for kk = 1:length(dims)
                        pos.([dims{kk}]) = ...
                            BMresults.results.parameters.positions.(dims{kk});
                        pos.([dims{kk}]) = squeeze(pos.([dims{kk}]));
                    end
                    pos.X = pos.X + alignment.Alignment.dx;
                    pos.Y = pos.Y + alignment.Alignment.dy;
                    pos.Z = pos.Z + alignment.Alignment.dz;
                    
                    %% Find the dimension of the measurement
                    dimensions = size(BS_mean, 1, 2, 3);
                    dimension = sum(dimensions > 1);
                    Brillouin.dimension = dimension;
                    
                    %% Find non-singular dimensions
                    nsdims = cell(dimension,1);
                    sdims = cell(dimension,1);
                    nsdimslabel = cell(dimension,1);
                    ind = 0;
                    sind = 0;
                    for kk = 1:length(dimensions)
                        if dimensions(kk) > 1
                            ind = ind + 1;
                            nsdims{ind} = dims{kk};
                            nsdimslabel{ind} = ['$' dimslabel{kk} '$ [$\mu$m]'];
                        else
                            sind = sind + 1;
                            sdims{sind} = dims{kk};
                        end
                    end
                    Brillouin.nsdims = nsdims;
                    Brillouin.nsdimslabel = nsdimslabel;
                    Brillouin.sdims = sdims;
                    
                    z0 = alignment.Alignment.z0;
                    
                    switch (Brillouin.dimension)
                        case 0
                        case 1
                            %% Plot Brillouin shift
                            plotData1D(parameters.path, BS_mean, pos, parameters.BM.shift.cax, '$\nu_\mathrm{B}$ [GHz]', ...
                                [alignmentFilename '_shift'], Brillouin, z0);

                            %% Plot Brillouin intensity
                            plotData1D(parameters.path, BI_mean, pos, parameters.BM.intensity.cax, '$I$ [a.u.]', ...
                                [alignmentFilename '_int'], Brillouin, z0);

                            %% Plot longitudinal modulus
                            plotData1D(parameters.path, M_mean, pos, parameters.Modulus.M.cax, ...
                                '$M$ [GPa]', [alignmentFilename '_modulus'], Brillouin, z0);

                        case 2
                            %% Calculate the FOV for the RI measurements
                            if isfield(BMresults.results.results, 'RISection')
                                nrPix = size(BMresults.results.results.RISection, 1);
                            else
                                nrPix = 342; %% Should be extracted correctly without hardcoding
                            end
                            res = 0.2530;
                            pos.X_RI = ((1:nrPix) - nrPix/2) * res;
                            pos.Y_RI = pos.X_RI;

                            %% Plot Brillouin Shift
                            names = {};
                            try
                                masks = BMresults.results.results.masks;
                            catch
                                masks = {};
                            end

                            plotData2D(parameters.path, BS_mean, pos, parameters.BM.shift.cax, '$\nu_\mathrm{B}$ [GHz]', ...
                                [alignmentFilename '_shift'], 0, masks, names);
                            plotData2D(parameters.path, BS_mean, pos, parameters.BM.shift.cax, '$\nu_\mathrm{B}$ [GHz]', ...
                                [alignmentFilename '_shift_outline'], 1, masks, names);

                            %% Plot Brillouin intensity
                            plotData2D(parameters.path, BI_mean, pos, parameters.BM.intensity.cax, '$I$ [a.u.]', ...
                                [alignmentFilename '_int'], 0, masks, names);

                            %% Plot longitudinal modulus
                            plotData2D(parameters.path, M_mean, pos, parameters.Modulus.M.cax, ...
                                '$M$ [GPa]', [alignmentFilename '_modulus'], 0, masks, names);
                    end
                catch
                end
            end
        end
        
        h5bmclose(file);
    catch
    end
    
    function plotData1D(plotPath, data, pos, cax, ylabelString, filename, Brillouin, z0)
        
        %% plot results
        figure;
        d = squeeze(data);
        p = squeeze(pos.(Brillouin.nsdims{1}));
        plot(p, d, 'marker', 'x');
        axis('normal');
        colorbar('off');
        xlim([min(p(:)), max(p(:))]);
        ylim(cax);
        xlabel(Brillouin.nsdimslabel{1}, 'interpreter', 'latex');
        ylabel(ylabelString, 'interpreter', 'latex');
        if strcmp(Brillouin.nsdims{1}, 'Z') && nargin == 8
            hold('on');
            plot([z0, z0], [min(cax), max(cax)], 'Linewidth', 1.5, 'color', [0.4660, 0.6740, 0.1880]);
%             patch([1 4 4 1] + z0, [min(cax) min(cax) max(cax) max(cax)], [255 105 65]/255, 'FaceAlpha', .1);
            hold('off');
        end
        
        layout = struct( ...
            'figpos', [1 1 10 6], ...
            'axepos', [0.15 0.17 0.8 0.74], ...
            'colpos', [0.82 0.17 0.059 0.74] ...
        );
        prepare_fig([plotPath filesep 'Plots' filesep 'WithAxis' filesep filename], ...
            'output', {'png', 'tikz'}, 'style', 'article', 'command', {'close'}, 'layout', layout);
    end
    
    function plotData2D(plotPath, data, pos, cax, colorbarTitle, filename, showOutline, masks, names)
        
        %% plot results
        figure;
        imagesc(pos.X(1,:), pos.Y(:,1), data, 'AlphaData', ~isnan(data));
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

                imagesc(pos.X(1,:), pos.Y(:,1), colorMask, 'AlphaData', masks.(field).transparency*double(outline));
            end
        end
        axis equal;
        axis([min(pos.X(:)), max(pos.X(:)), min(pos.Y(:)), max(pos.Y(:))]);
        caxis(cax);
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
            'figpos', [1 1 10 6], ...
            'axepos', [0.10 0.17 0.7 0.74], ...
            'colpos', [0.82 0.17 0.059 0.74] ...
        );
        prepare_fig([plotPath filesep 'Plots' filesep 'WithAxis' filesep filename], ...
            'output', 'png', 'style', 'article', 'layout', layout);
        
        % Also export the plot with the ODT FOV limits
        axis([min(pos.X_RI(:)), max(pos.X_RI(:)), min(pos.Y_RI(:)), max(pos.Y_RI(:))]);
        layout = struct( ...
            'figpos', [1 1 8 6], ...
            'axepos', [0.10 0.17 0.7 0.74], ...
            'colpos', [0.8 0.17 0.059 0.74] ...
        );
        prepare_fig([plotPath filesep 'Plots' filesep 'WithAxis' filesep filename '_fullFOV'], ...
            'output', 'png', 'style', 'article', 'command', {'close'}, 'layout', layout);

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

        map = parula(2^8);
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
        [X, Y] = meshgrid(pos.X(1,:), pos.Y(:,1));
        xmin = min(pos.X_RI);
        xmax = max(pos.X_RI);
        nrPosX = round((xmax - xmin)/abs(pos.X(1,1) - pos.X(1,2)));
        x_new = linspace(xmin, xmax, nrPosX);
        ymin = min(pos.X_RI);
        ymax = max(pos.X_RI);
        nrPosY = round((ymax - ymin)/abs(pos.Y(1,1) - pos.Y(2,1)));
        y_new = linspace(xmin, xmax, nrPosY);
        [X_RI, Y_RI] = meshgrid(x_new, y_new);
        
        RGB_fullFOV(:,:,1) = interp2(X, Y, RGB(:,:,1), X_RI, Y_RI, 'nearest');
        RGB_fullFOV(:,:,2) = interp2(X, Y, RGB(:,:,2), X_RI, Y_RI, 'nearest');
        RGB_fullFOV(:,:,3) = interp2(X, Y, RGB(:,:,3), X_RI, Y_RI, 'nearest');
        
        transparent = double(~isnan(RGB_fullFOV(:,:,1)));

        imwrite(RGB_fullFOV, [plotPath filesep 'Plots' filesep 'Bare' filesep filename '_fullFOV_bare.png'], 'BitDepth', 8, 'Alpha', transparent);
    end
end