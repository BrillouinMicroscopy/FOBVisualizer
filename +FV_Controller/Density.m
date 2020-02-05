function callbacks = Density(model, view)
%% DATA Controller
    
    %% general panel
    set(view.Density.n0, 'Callback', {@setValue, model, 'n0'});
    set(view.Density.alpha, 'Callback', {@setValue, model, 'alpha'});
    set(view.Density.rho0, 'Callback', {@setValue, model, 'rho0'});
    
    set(view.Density.useDryDensity, 'Callback', {@toggleUseDryDensity, model, view});
    set(view.Density.rho_dry, 'Callback', {@setValue, model, 'rho_dry'});

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
            RI = interp3(ODT.positions.x, ODT.positions.y, ODT.positions.z, ODT.data.Reconimg, ...
                Alignment.dx + positions.x, Alignment.dy + positions.y, Alignment.dz + positions.z);
            
            RI = repmat(RI, 1, 1, 1, size(Brillouin.shift, 4));

            %% Calculate density
            % If requested, we use the absolute density of the dry fraction
            % to calculate the density, otherwise we neglect the
            % contribution.
            if density.useDryDensity
                rho = (RI - density.n0)/density.alpha + density.rho0 * (1 - (RI - density.n0)/density.alpha / density.rho_dry);
            else
                rho = (RI - density.n0)/density.alpha + density.rho0;
            end
            rho = 1e3*rho;      % [kg/m^3]  density of the sample

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
    model.density.(value) = str2double(get(src, 'String'));
    calculateDensity(model);
end

function toggleUseDryDensity(~, ~, model, view)
    model.density.useDryDensity = get(view.Density.useDryDensity, 'Value');
    calculateDensity(model);
end