function plotRefractiveIndex(filename, settings)

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

    RI = results.results.results.RISection;
    
    nrPix = size(RI, 1);
    res = 0.2530;
    pos.x = ((1:nrPix)-nrPix/2)*res;
    pos.y = pos.x;

    %% Plot refractive index
    plotData(plotPath, RI, pos, settings.cax, '$n$', filename);
    
    function plotData(plotPath, data, pos, cax, colorbarTitle, filename)
        
        
        %% plot results
        figure;
        imagesc(pos.x, pos.y, data, 'AlphaData', ~isnan(data));
        hold on;
        axis equal;
        axis([min(pos.x), max(pos.x), min(pos.y), max(pos.y)]);
        caxis([cax.min cax.max]);
        colormap('jet');
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
        prepare_fig([plotPath filesep 'Plots' filesep 'WithAxis' filesep filename '_RefractiveIndex'], ...
            'output', {'png'}, 'style', 'article', 'command', {'close'}, 'layout', layout);

        %% print image without axis and colorbar

        pixelValues = data;
        pixelValues = rot90(pixelValues,2);
        pixelValues = fliplr(pixelValues);

        % set caxis for png image
        pixelValues(pixelValues < cax.min) = cax.min;
        pixelValues(pixelValues > cax.max) = cax.max;

        % scale image values to 'bitdepth' bit
        pixelValues = pixelValues - cax.min;
        pixelValues = round(2^8*pixelValues/(cax.max-cax.min));

        map = jet(2^8);
        RGB = ind2rgb(pixelValues, map);
    
        imwrite(RGB,[plotPath filesep 'Plots' filesep 'Bare' filesep filename '_RefractiveIndex.png'], 'BitDepth', 8);

    end
end