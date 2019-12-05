function callbacks = Alignment(model, view)
%% ALIGNMENT Controller
% 
    set(view.Alignment.start, 'Callback', {@start, view, model});
    
    set(view.Alignment.save, 'Callback', {@save, view, model});
    set(view.Alignment.cancel, 'Callback', {@closeAlignment, model, view});
    
    set(view.Alignment.dx, 'Callback', {@setAlignment, 'dx', model});
    set(view.Alignment.dy, 'Callback', {@setAlignment, 'dy', model});
    set(view.Alignment.dz, 'Callback', {@setAlignment, 'dz', model});
    
    %% general panel

    callbacks = struct( ...
    );
end

function start(~, ~, view, model)
    Brillouin = model.Brillouin;
    ODT = model.ODT;
    
    BMZres = 2;     % [µm]  resolution of the BM measurement in z-direction
    
    if ~isempty(Brillouin.repetitions) && ~isempty(ODT.repetitions)
        try
            BS = nanmean(Brillouin.shift, 4);
            positions = Brillouin.positions;

            dimensions = size(BS);
            dimension = sum(dimensions > 1);

            %% find non-singular dimensions
            dims = {'y', 'x', 'z'};
            nsdims = cell(dimension,1);
            sdims = cell(dimension,1);
            ind = 0;
            sind = 0;
            for jj = 1:length(dimensions)
                if dimensions(jj) > 1
                    ind = ind + 1;
                    nsdims{ind} = dims{jj};
                else
                    sind = sind + 1;
                    sdims{sind} = dims{jj};
                end
            end
            Brillouin.nsdims = nsdims;
            
            switch (dimension)
                case 0
                case 1
                    %% one dimensional case
                case 2
                    %% two dimensional case
                    BS = squeeze(BS);
                    pos.x = squeeze(positions.x);
                    pos.y = squeeze(positions.y);
                    pos.z = squeeze(positions.z);
                    
                    %% ODT positions
                    ZP4 = round(size(ODT.data.Reconimg,1));
                    x = ((1:ZP4)-ZP4/2)*ODT.data.res3;
                    y = x;

                    ZP5 = round(size(ODT.data.Reconimg,3));
                    z = ((1:ZP5)-ZP5/2)*ODT.data.res4;

                    [X, Y] = meshgrid(x, y);
                    
                    %% Interpolate Brillouin shift to match ODT resolution
                    BS_int = interp2(pos.x, pos.y, BS, X, Y);
                    
                    % Select FOV matching BM FOV
                    tempInd = find(~isnan(BS_int));
                    [tempX, tempY] = ind2sub(size(BS_int), tempInd);
                    Reconimgtemp = ODT.data.Reconimg(min(tempX):max(tempX), min(tempY):max(tempY), :);   % select RI regions matching with BS FOV
                    BS_int = BS_int(min(tempX):max(tempX), min(tempY):max(tempY));                      % select interpolated BS maps matching with BS FOV
                    BS_int_zm = BS_int - mean2(BS_int);
                    
                    %% Actual correlation
                    corrMaxVal = NaN(size(ODT.data.Reconimg, 3) - round(BMZres/ODT.data.res4), 1);
                    corrMaxInd = NaN(size(ODT.data.Reconimg, 3) - round(BMZres/ODT.data.res4), 1);
                    
                    zetts = 1:(size(ODT.data.Reconimg, 3) - round(BMZres/ODT.data.res4));
                    for z = zetts
                        testVol = mean(Reconimgtemp(:,:, (0:round(BMZres/ODT.data.res4)) + z), 3);                   % averaged RI map in the focal volume
                        testVol = testVol - mean2(testVol);
                        corrVal = xcorr2(testVol, BS_int_zm); % calculate the cross-correlation
                        [corrMaxVal(z), corrMaxInd(z)] = max(corrVal(:));
                        
                        view.Alignment.ODT_plot = imagesc(view.Alignment.ODT, testVol);
                        view.Alignment.map_plot = imagesc(view.Alignment.map, corrVal);
                        view.Alignment.coeff_plot = plot(view.Alignment.coeff, zetts, corrMaxVal, 'or');
                        
                        set(view.Alignment.map, 'YDir', 'normal');
                        set(view.Alignment.ODT, 'YDir', 'normal');
                        xlim(view.Alignment.coeff, [1 max(zetts)]);
                        colormap(view.Alignment.ODT, 'jet');
                        
                        drawnow;
                    end
                    
                    [~, indZ] = max(corrMaxVal(:));
                    [indX, indY] = ind2sub(size(corrVal), corrMaxInd(indZ)); 
                    
                    temporary = model.temporary;
                    temporary.Alignment.dx_tmp = (indX - (size(BS_int_zm, 1) + size(Reconimgtemp, 1)) / 2) * ODT.data.res3;
                    temporary.Alignment.dy_tmp = (indY - (size(BS_int_zm, 2) + size(Reconimgtemp, 2)) / 2) * ODT.data.res3;
                    temporary.Alignment.dz_tmp = (indZ - size(zetts, 2)/2) * ODT.data.res4;
                    set(view.Alignment.dx, 'String', temporary.Alignment.dx_tmp);
                    set(view.Alignment.dy, 'String', temporary.Alignment.dy_tmp);
                    set(view.Alignment.dz, 'String', temporary.Alignment.dz_tmp);
                    model.temporary = temporary;
                    
                case 3
            end
        catch e
            disp(e);
        end
    end
end

function save(~, ~, view, model)
    %% save data here
    Alignment = model.Alignment;
    if isfield(model.temporary.Alignment, 'dx_tmp')
        Alignment.dx = model.temporary.Alignment.dx_tmp;
    end
    if isfield(model.temporary.Alignment, 'dy_tmp')
        Alignment.dy = model.temporary.Alignment.dy_tmp;
    end
    if isfield(model.temporary.Alignment, 'dz_tmp')
        Alignment.dz = model.temporary.Alignment.dz_tmp;
    end
    model.Alignment = Alignment;
%     %% close alignment window
%     closeAlignment(0, 0, model, view);
end

function closeAlignment(~, ~, model, view)
%     %% delete temporary values
%     if isfield(model.temporary.Alignment, 'dx_tmp')
%         model.Alignment = rmfield(model.Alignment, 'dx_tmp');
%     end
%     if isfield(model.temporary.Alignment, 'dy_tmp')
%         model.Alignment = rmfield(model.Alignment, 'dy_tmp');
%     end
%     if isfield(model.temporary.Alignment, 'dz_tmp')
%         model.Alignment = rmfield(model.Alignment, 'dz_tmp');
%     end
    close(view.Alignment.parent);
end

function setAlignment(src, ~, type, model)
    model.temporary.Alignment.([type '_tmp']) = str2double(get(src, 'String'));
end