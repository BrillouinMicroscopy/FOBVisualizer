function plotCombinedFluorescence(filename)

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

    %% plot the measurement results
    results = load(['EvalData' filesep filename '.mat']);
    
    fluorescence = results.results.results.combinedImage;
    fluorescence = flipud(fluorescence);

    imwrite(fluorescence,[plotPath filesep 'Plots' filesep 'Bare' filesep filename '_fluorescenceCombined.png'], 'BitDepth', 8);
end