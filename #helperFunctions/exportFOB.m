%% Exports data of the FOB microscope for LaTeX

filename = 'Brillouin-1';

%% Refractive index
RIsettings.cax.min = 1.337;
RIsettings.cax.max = 1.50;
plotRefractiveIndex(filename, RIsettings);

%% Fluorescence and Brightfield
plotFluorescence(filename);
plotCombinedFluorescence(filename);

%% Brillouin shift and longitudinal modulus

% caxis limits for the Brillouin shift
BMsettings.cax.shift.min = 6.85;
BMsettings.cax.shift.max = 7.2;
% caxis limits for the Brillouin intensity
BMsettings.cax.int.min = 0;
BMsettings.cax.int.max = 1;
% caxis limits for the longitudinal modulus
BMsettings.cax.lm.min = 1.75;
BMsettings.cax.lm.max = 2.04;
BMsettings.cax.lm_no_RI.min = -15;
BMsettings.cax.lm_no_RI.max = 15;
% limit for the validity
BMsettings.validityLimit = 40;

plotBrillouinModulus(filename, BMsettings);
plotBrillouinModulusDeviation(filename, BMsettings);

