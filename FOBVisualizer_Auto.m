function FOBVisualizer_Auto(filelist, parameters)
% function for automatically evaluating Brillouin data

%% start evaluation program
[controllers, model] = FOBVisualizer;
drawnow;

for jj = 1:length(filelist)
    try
        %% construct filename
        loadFile = [filelist(jj).folder filesep filelist(jj).name];
        if ~exist(loadFile, 'file')
            continue;
        end

        %% load the data file
        controllers.data.openFile(loadFile);
        
        for ii = 1:length(model.ODT.repetitions)
            for kk = 1:length(model.Brillouin.repetitions)
                try
                    %% set current repetition
                    ODTrep.index = ii;
                    ODTrep.name = model.ODT.repetitions{ii};
                    model.ODT.repetition = ODTrep;
                    
                    BMrep.index = kk;
                    BMrep.name = model.Brillouin.repetitions{kk};
                    model.Brillouin.repetition = BMrep;
                    
                    controllers.ODT.loadRepetition();
                    controllers.Brillouin.loadRepetition();
                    controllers.data.loadAlignmentData();
                    
                    controllers.data.setParameters(parameters);
                    drawnow;

                    %% align ODT and BM
                    if parameters.Alignment.do
                        controllers.data.openAlignment();
                        model.controllers.Alignment.start();
                        model.controllers.Alignment.save();
                        model.controllers.Alignment.close();
                        drawnow;
                    end

                    %% calculate density and modulus
                    if parameters.density.do
                        controllers.density.calculateDensity();
                        drawnow;
                    end

                    %% save the data file
                    controllers.data.save();
                catch e
                    disp(e);
                end
            end
        end

        %% close the rawdata file
        controllers.data.closeFile();
    catch e
        disp(e);
    end
end
        
controllers.closeGUI();
