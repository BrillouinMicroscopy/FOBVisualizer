function plotBrillouinModulusDeviation(filename, settings)

    plotPath = '.';
    
    %% directory for the plots
    plotDir = 'Plots';
    if ~exist(plotDir, 'dir')
        mkdir(plotDir);
    end
    barePlotDir = ['Plots' filesep 'Bare'];
    if ~exist(barePlotDir, 'dir')
        mkdir(barePlotDir);
    end
    axisPlotDir = ['Plots' filesep 'WithAxis'];
    if ~exist(axisPlotDir, 'dir')
        mkdir(axisPlotDir);
    end

    %% plot the measurement results
    results = load(['EvalData' filesep filename '.mat']);

    LongitudinalModulus = results.results.results.longitudinalModulus;
    LongitudinalModulus_without_RI = results.results.results.longitudinalModulus_without_RI;
    validity = results.results.results.validity;
    validityLevel = results.results.results.peaksBrillouin_dev./results.results.results.peaksBrillouin_int;

    dims = {'X', 'Y', 'Z'};
    for kk = 1:length(dims)
        pos.([dims{kk} '_zm']) = ...
            results.results.parameters.positions.(dims{kk});
        pos.([dims{kk} '_zm']) = squeeze(pos.([dims{kk} '_zm']));
    end
    
    %% Calculate the FOV for the RI measurements
    nrPix = size(results.results.results.RISection, 1);
    res = 0.2530;
    pos.X_zm_RI = ((1:nrPix)-nrPix/2)*res;
    pos.Y_zm_RI = pos.X_zm_RI;

    names = {};
    try
        masks = results.results.results.masks;
    catch
        masks = {};
    end
    
    %% Plot longitudinal modulus without RI
    % filter invalid values
    LongitudinalModulus_without_RI(~validity) = NaN;
    LongitudinalModulus_without_RI(validityLevel > settings.validityLimit) = NaN;

    plotData(plotPath, 1e2*(LongitudinalModulus - LongitudinalModulus_without_RI) / min(LongitudinalModulus(:)), pos, settings.cax.lm_no_RI, '$\Delta M$ [\%]', [filename '_longitudinalModulus_without_RI'], 0, masks, names);
    
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
        caxis([cax.min cax.max]);
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
        pixelValues(pixelValues < cax.min) = cax.min;
        pixelValues(pixelValues > cax.max) = cax.max;

        % transparency matrix
        transparent = double(~isnan(pixelValues));

        % scale image values to 'bitdepth' bit
        pixelValues = pixelValues - cax.min;
        pixelValues = round(2^8*pixelValues/(cax.max-cax.min));

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