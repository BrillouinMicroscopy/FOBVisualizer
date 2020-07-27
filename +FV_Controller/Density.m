function callbacks = Density(model, view)
%% DATA Controller
    
    %% general panel
    set(view.Density.n0, 'ValueChangedFcn', {@setValue, model, 'n0'});
    set(view.Density.alpha, 'ValueChangedFcn', {@setValue, model, 'alpha'});
    set(view.Density.rho0, 'ValueChangedFcn', {@setValue, model, 'rho0'});
    
    set(view.Density.useDryDensity, 'ValueChangedFcn', {@toggleUseDryDensity, model, view});
    set(view.Density.rho_dry, 'ValueChangedFcn', {@setValue, model, 'rho_dry'});
    
    set(view.Density.openMasking, 'ButtonPushedFcn', {@openMasking, view, model});

    callbacks = struct( ...
        'calculateDensity', @()calculateDensity(model) ...
    );
end

function calculateDensity(model)
    Brillouin = model.Brillouin;
    ODT = model.ODT;
    Alignment = model.Alignment;
    density = model.density;
    
    %% Calculate the density
    if ~(isempty(Brillouin.repetitions) || isempty(model.ODT.repetitions))
        try
            positions = Brillouin.positions;

            %% Calculate the absolute density from the measured RI
            BMZres = 2;
            dz = linspace(-BMZres/2, BMZres/2, 1 + round(BMZres/ODT.data.res4));
            dz = dz - mean2(dz);
            x = Alignment.dx + positions.x;
            y = Alignment.dy + positions.y;
            z = Alignment.dz + positions.z;
            
            intZ = NaN(size(z,3)*numel(dz), 1);
            for jj = 1:size(z,3)
                intZ((1:numel(dz)) + (jj-1)*numel(dz)) = z(1,1,jj) + dz;
            end
            [X, Y, Z] = meshgrid(x(1,:,1), y(:,1,1), intZ);
            RI_tmp = interp3(ODT.positions.x, ODT.positions.y, ODT.positions.z, ODT.data.Reconimg, ...
                X, Y, Z);
            
            RI = NaN(size(z));
            for jj = 1:size(z,3)
                RI(:,:,jj) = nanmean(RI_tmp(:,:,(1:numel(dz)) + (jj-1)*numel(dz)), 3);
            end

            %% Calculate density
            % If requested, we use the absolute density of the dry fraction
            % to calculate the density, otherwise we neglect the
            % contribution.
            if density.useDryDensity
                rho = (RI - density.n0)/density.alpha + density.rho0 * (1 - (RI - density.n0)/density.alpha / density.rho_dry);
            else
                rho = (RI - density.n0)/density.alpha + density.rho0;
            end
            
            %% Apply density masks
            masks = model.density.masks;
            masksFields = fields(masks);
            m_sum = zeros(size(rho,1), size(rho,2));
            for jj = 1:length(masksFields)
                mask = masks.(masksFields{jj});
                if ~mask.active
                    continue
                end
                switch (mask.parameter)
                    case 'Refractive index'
                        m = ones(size(RI));
                        m(RI > mask.max | RI < mask.min) = 0;
                        m = imgaussfilt(m,0.5);
                    case 'Brillouin shift'
                        BS = nanmean(model.Brillouin.shift, 4);
                        m = ones(size(BS));
                        m(BS > mask.max | BS < mask.min) = 0;
                        m = imgaussfilt(m,0.5);
                    otherwise
                        try
                            reps = model.Fluorescence.repetitions;
                            for ll = 1:length(reps)
                                channels = model.file.readPayloadData('Fluorescence', model.Fluorescence.repetitions{ll}, 'memberNames');
                                for kk = 1:length(channels)
                                    flType = model.file.readPayloadData('Fluorescence', model.Fluorescence.repetitions{ll}, 'channel', channels{kk});
                                    if (strcmp(mask.parameter, [sprintf('Fl. rep. %01.0d, ', ll) flType]))
                                        fluorescence = model.file.readPayloadData('Fluorescence', model.Fluorescence.repetitions{ll}, 'data', channels{kk});
                                        fluorescence = medfilt1(fluorescence, 3);
                                        break;
                                    end
                                end
                                if exist('fluorescence', 'var')
                                    break
                                end
                            end

                            x = 4.8*(1:size(fluorescence, 1))/57;
                            x = x - nanmean(x(:));
                            y = 4.8*(1:size(fluorescence, 2))/57;
                            y = y - nanmean(y(:));

                            FL = interp2(x, y, fluorescence, ...
                                model.Brillouin.positions.x(1,:), model.Brillouin.positions.y(:,1));

                            m = ones(size(FL));
                            m(FL > mask.max | FL < mask.min) = 0;
                            m = imgaussfilt(m,0.5);
                        catch
                            m = zeros(size(density.rho,1), size(density.rho,2));
                        end
                end
                masks.(masksFields{jj}).m = m;
                m_sum = m_sum + m;
            end
            m0 = 1 - m_sum;
            m0(m0 < 0) = 0;
            rho = m0 .* rho;
            norm = m_sum + m0;
            for jj = 1:length(masksFields)
                mask = masks.(masksFields{jj});
                if ~mask.active
                    continue
                end
                weight = mask.m./ norm;
                rho = rho + weight .* mask.density;
            end
            
            rho = 1e3*rho;      % [kg/m^3]  density of the sample
            
            rho = repmat(rho, 1, 1, 1, size(Brillouin.shift, 4), size(Brillouin.shift, 5));
            RI = repmat(RI, 1, 1, 1, size(Brillouin.shift, 4), size(Brillouin.shift, 5));

            %% Save to structure
            density.RI = RI;
            density.rho = rho;

            %% Write data to model
            model.density = density;
            
            %% Update longitudinal modulus
            model.controllers.modulus.calculateModulus();
        catch
        end
    end
end

function setValue(src, ~, model, value)
    model.density.(value) = get(src, 'Value');
    calculateDensity(model);
end

function toggleUseDryDensity(~, ~, model, view)
    model.density.useDryDensity = get(view.Density.useDryDensity, 'Value');
    calculateDensity(model);
end

function openMasking(~, ~, view, model)    
    if isfield(view.DensityMasking, 'parent') && ishandle(view.DensityMasking.parent)
        figure(view.DensityMasking.parent);
        return;
    end
    
    % open it centered over main figure
    pos = view.figure.Position;
    parent = figure('Position', [pos(1) + pos(3)/2 - 450, pos(2) + pos(4)/2 - 325, 900, 650]);
    % hide the menubar and prevent resizing
    set(parent, 'menubar', 'none', 'Resize','off', 'units', 'pixels');
    
    view.DensityMasking.parent = parent;

    model.tmp.masks = model.density.masks;
    model.tmp.selectedMask = 1;
    FV_View.DensityMasking(view, model);

    model.controllers.DensityMasking = FV_Controller.DensityMasking(model, view);
end