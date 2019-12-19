function callbacks = Modulus(model, view)
%% DATA Controller
    
    %% general panel
    set(view.Modulus.n0, 'Callback', {@setValue, model, 'n0'});
    set(view.Modulus.alpha, 'Callback', {@setValue, model, 'alpha'});
    set(view.Modulus.rho0, 'Callback', {@setValue, model, 'rho0'});
    
    set(view.Modulus.useDryDensity, 'Callback', {@toggleUseDryDensity, model, view});
    set(view.Modulus.rho_dry, 'Callback', {@setValue, model, 'rho_dry'});

    callbacks = struct( ...
        'calculateModulus', @()calculateModulus(model) ...
    );
end

function calculateModulus(model)
    modulus = model.modulus;
    Brillouin = model.Brillouin;
    ODT = model.ODT;
    Alignment = model.Alignment;
    
    %% Calculate the modulus
    if ~(isempty(Brillouin.repetitions) || isempty(model.ODT.repetitions))
        try
            positions = Brillouin.positions;

            %% Calculate the longitudinal modulus with measured RI
            RI = interp3(ODT.positions.x, ODT.positions.y, ODT.positions.z, ODT.data.Reconimg, ...
                Alignment.dx + positions.x, Alignment.dy + positions.y, Alignment.dz + positions.z);
            
            RI = repmat(RI, 1, 1, 1, size(Brillouin.shift, 4));

            %% Calculate density
            % If requested, we use the absolute density of the dry fraction
            % to calculate the density, otherwise we neglect the
            % contribution.
            if modulus.useDryDensity
                rho = (RI - modulus.n0)/modulus.alpha + modulus.rho0 * (1 - (RI - modulus.n0)/modulus.alpha / modulus.rho_dry);
            else
                rho = (RI - modulus.n0)/modulus.alpha + modulus.rho0;
            end
            rho = 1e3*rho;      % [kg/m^3]  density of the sample

            zeta = (2*cos(Brillouin.setup.theta/2) * RI) ./ (Brillouin.setup.lambda * sqrt(rho));

            % calculate M'
            M = (1e9*Brillouin.shift./zeta).^2;
            
            %% Calculate the longitudinal modulus without measured RI
            RI_woRI = modulus.n0 * ones(size(Brillouin.shift));
            rho_woRI = 1e3*modulus.rho0;
            
            zeta_woRI = (2*cos(Brillouin.setup.theta/2) * RI_woRI) ./ (Brillouin.setup.lambda * sqrt(rho_woRI));
            
            % calculate M'
            M_woRI = (1e9*Brillouin.shift./zeta_woRI).^2;

            %% Save to structure
            modulus.M = M;
            modulus.M_woRI = M_woRI;
            modulus.RI = RI;
            modulus.rho = rho;

            %% Write data to model
            model.modulus = modulus;
        catch
        end
    end
end

function setValue(src, ~, model, value)
    model.modulus.(value) = str2double(get(src, 'String'));
    calculateModulus(model);
end

function toggleUseDryDensity(~, ~, model, view)
    model.modulus.useDryDensity = get(view.Modulus.useDryDensity, 'Value');
    calculateModulus(model);
end