function callbacks = Alignment(model, view)
%% ALIGNMENT Controller
%     
    set(view.Alignment.start, 'Callback', {@start, model, view});
    
    set(view.Alignment.save, 'Callback', {@save, model, view});
    set(view.Alignment.cancel, 'Callback', {@closeAlignment, view});
    
    %% general panel

    callbacks = struct( ...
    );
end

function start(~, ~, model, view)
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

%                     ZP5 = round(size(ODT.data.Reconimg,3));
%                     z = ((1:ZP5)-ZP5/2)*ODT.data.res4;

                    [X, Y] = meshgrid(x, y);
                    
                    %% Interpolate NaNs in case there are some
                    if sum(isnan(BS(:))) > 0
                       BS = FV_Utils.Inpaint_Nans.inpaint_nans(BS); 
                    end
                    
                    %% Interpolate Brillouin shift to match ODT resolution
                    BS_int = interp2(pos.x, pos.y, BS, X, Y);
                    
                    % Select FOV matching BM FOV
                    tempInd = find(~isnan(BS_int));
                    [tempX, tempY] = ind2sub(size(BS_int), tempInd);
                    Reconimgtemp = ODT.data.Reconimg(min(tempX):max(tempX), min(tempY):max(tempY), :);   % select RI regions matching with BS FOV
                    BS_int = BS_int(min(tempX):max(tempX), min(tempY):max(tempY));                      % select interpolated BS maps matching with BS FOV
                    BS_int_zm = BS_int - mean2(BS_int);
                    
                    [BS_int_zm_dx, BS_int_zm_dy] = gradient(BS_int_zm);
                    BS_int_zm_grad = sqrt(BS_int_zm_dx.^2 + BS_int_zm_dy.^2);
                    
                    %% Actual correlation
                    corrMaxVal = NaN(size(ODT.data.Reconimg, 3) - round(BMZres/ODT.data.res4), 1);
                    corrMaxInd = NaN(size(ODT.data.Reconimg, 3) - round(BMZres/ODT.data.res4), 1);
                    
                    zetts = 1:(size(ODT.data.Reconimg, 3) - round(BMZres/ODT.data.res4));
                    for z = zetts
                        testVol = mean(Reconimgtemp(:,:, (0:round(BMZres/ODT.data.res4)) + z), 3);                   % averaged RI map in the focal volume
                        
                        [RI_dx, RI_dy] = gradient(testVol);
                        RI_grad = sqrt(RI_dx.^2 + RI_dy.^2);
                        
                        corrVal = xcorr2(RI_grad, BS_int_zm_grad); % calculate the cross-correlation
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
                    
                    %% Find more exact x-y-alignment
                    % we have to interpolate RI and BS in order to get a
                    % better alignment
                    intFac = 5; % interpolation factor
                    x_int = linspace(min(positions.x(:)), max(positions.x(:)), intFac * size(positions.x, 2));
                    y_int = linspace(min(positions.y(:)), max(positions.y(:)), intFac * size(positions.y, 1));
                    [X_int, Y_int] = meshgrid(x_int, y_int);
                    
                    BS_int = interp2(positions.x(:,:,1), positions.y(:,:,1), BS, X_int, Y_int);
                    [BS_int_dx, BS_int_dy] = gradient(BS_int);
                    BS_int_grad = sqrt(BS_int_dx.^2 + BS_int_dy.^2);
                    
                    RI = mean(ODT.data.Reconimg(:,:, (0:round(BMZres/ODT.data.res4)) + indZ), 3);
                    RI_int = interp2(ODT.positions.x(:,:,1), ODT.positions.y(:,:,1), RI, X_int, Y_int);
                    [RI_int_dx, RI_int_dy] = gradient(RI_int);
                    RI_int_grad = sqrt(RI_int_dx.^2 + RI_int_dy.^2);
                    
                    corrVal = xcorr2(BS_int_grad, RI_int_grad);
                    [~, ind] = max(corrVal(:));
                    [indX, indY] = ind2sub(size(corrVal), ind);
                    
                    %% Save values
                    dx = -1 * (indY - (size(BS_int_grad, 2) + size(RI_int_grad, 2)) / 2) * ...
                        (Y_int(2,1) - Y_int(1,1));
                    dy = -1 * (indX - (size(BS_int_grad, 1) + size(RI_int_grad, 1)) / 2) * ...
                        (X_int(1,2) - X_int(1,1));
                    dz = (indZ - size(zetts, 2)/2) * ODT.data.res4;
                    set(view.Alignment.dx, 'String', dx);
                    set(view.Alignment.dy, 'String', dy);
                    set(view.Alignment.dz, 'String', dz);
                    
                case 3
            end
        catch e
            disp(e);
        end
    end
end

function save(~, ~, model, view)
    %% save data here
    Alignment = model.Alignment;
    changed = false;
    dx = str2double(get(view.Alignment.dx, 'String'));
    if Alignment.dx ~= dx
        Alignment.dx = dx;
        changed = true;
    end
    dy = str2double(get(view.Alignment.dy, 'String'));
    if Alignment.dy ~= dy
        Alignment.dy = dy;
        changed = true;
    end
    dz = str2double(get(view.Alignment.dz, 'String'));
    if Alignment.dz ~= dz
        Alignment.dz = dz;
        changed = true;
    end
    if changed
        model.Alignment = Alignment;
    end
end

function closeAlignment(~, ~, view)
    close(view.Alignment.parent);
end