function callbacks = Modulus(model, ~)
%% MODULUS Controller
    
    %% general panel
    callbacks = struct( ...
        'calculateModulus', @()calculateModulus(model) ...
    );
end

function calculateModulus(model)
    modulus = model.modulus;
    Brillouin = model.Brillouin;
    density = model.density;
    
    %% Calculate the modulus
    if ~(isempty(Brillouin.repetitions) || isempty(model.ODT.repetitions))
        try
            zeta = (2*cos(Brillouin.setup.theta/2) * density.RI) ./ (Brillouin.setup.lambda * sqrt(density.rho));

            % calculate M'
            M = (1e9*Brillouin.shift./zeta).^2;
            
            %% Calculate the longitudinal modulus without measured RI
            RI_woRI = density.n0 * ones(size(Brillouin.shift));
            rho_woRI = 1e3*density.rho0;
            
            zeta_woRI = (2*cos(Brillouin.setup.theta/2) * RI_woRI) ./ (Brillouin.setup.lambda * sqrt(rho_woRI));
            
            % calculate M'
            M_woRI = (1e9*Brillouin.shift./zeta_woRI).^2;

            %% Save to structure
            modulus.M = M;
            modulus.M_woRI = M_woRI;

            %% Write data to model
            model.modulus = modulus;
        catch
        end
    end
end