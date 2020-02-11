classdef View < handle
%% VIEW

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        data;
        ODT;
        Fluorescence;
        Brillouin;
        Density;
        Modulus
        help;
        figure;
        menubar;
        Alignment;
        DensityMasking;
    end

    methods
        function obj = View()
        end
    end
end