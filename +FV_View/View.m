classdef View < handle
%% VIEW

    % observable properties, listeners are notified on change
    properties (SetObservable = true)
        data;
        ODT;
        Fluorescence;
        Brillouin;
        Modulus
        help;
        figure;
        menubar;
    end

    methods
        function obj = View()
        end
    end
end