function callbacks = Modulus(model, ~)
%% DATA Controller
    
    %% general panel

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

            RI = interp3(ODT.positions.x, ODT.positions.y, ODT.positions.z, ODT.data.Reconimg, ...
                Alignment.dx + positions.x, Alignment.dy + positions.y, Alignment.dz + positions.z);
            
            RI = repmat(RI, 1, 1, 1, size(Brillouin.shift, 4));

            % calculate density
            rho = (RI - modulus.n0)/modulus.alpha + modulus.rho0;
            rho = 1e3*rho;      % [kg/m^3]  density of the sample

            zeta = (2*cos(Brillouin.setup.theta/2) * RI) ./ (Brillouin.setup.lambda * sqrt(rho));

            % calculate M'
            M = (1e9*Brillouin.shift./zeta).^2;

            modulus.M = M;
            modulus.RI = RI;
            modulus.rho = rho;

            %% Write data to model
            model.modulus = modulus;
        catch
        end
    end
end