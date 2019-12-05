%% Input: Tomogram, Brillouin Shift

load('EvalData\Brillouin-2.mat');
load('EvalData\Tomogram_Field_Brillouin-2');

%% Define Dimension Parameters
BMFrequency = results.results.BrillouinShift_frequency;
Xq = results.parameters.positions.X;
Yq = results.parameters.positions.Y;

BMZres = 2;                                 % [µm]  Hard-coded axial resolution. Can be modified
BMFrequency = squeeze(mean(BMFrequency, 4));% Average BS map in repetitions
% BMFrequency_zm = BMFrequency - mean2(BMFrequency);
ZP4 = round(size(Reconimg, 1));             % lateral dimension in x and y (tomogram has the same x and y dimension)
ZP5 = size(Reconimg, 3);                    % axial dimension

%% Tomogram and BS interpolation
[X, Y] = meshgrid(((1:ZP4)-ZP4/2)*res3, ((1:ZP4)-ZP4/2)*res3);  % extract pixel positions in the tomogram
[Xq, Yq] = meshgrid(Xq(1,:), Yq(:,1));                          % extract pixel positions in the BS
Vq = interp2(Xq, Yq, BMFrequency, X, Y);                        % interpolate BS map to make the same resolution as the tomogram

tempInd = find(~isnan(Vq));
[tempX, tempY] = ind2sub(size(Vq), tempInd);
Reconimgtemp = Reconimg(min(tempX):max(tempX), min(tempY):max(tempY), :);   % select RI regions matching with BS FOV
Vq = Vq(min(tempX):max(tempX), min(tempY):max(tempY));                      % select interpolated BS maps matching with BS FOV
BMFrequency_zm = Vq - mean2(Vq);

%% Finding axial plane for BS in Tomogram
% z = 43; is a default axial position, especially when you did not change the
% axial position of the upper objective lens during the fluorescence
% measurement and Brillouin

corrMaxVal = zeros(size(Reconimg, 3) - round(BMZres/res4), 1);

for z = 1:(size(Reconimg, 3) - round(BMZres/res4))
    testVol = mean(Reconimgtemp(:,:, (0:round(BMZres/res4)) + z), 3);                   % averaged RI map in the focal volume
    corrVal = xcorr2(testVol - mean2(testVol), BMFrequency_zm); % calculate the cross-correlation
    corrMaxVal(z) = max(corrVal(:));

    %% Plot
    figure(100);
    subplot(231);
    imagesc(testVol);
    axis image;
    axis off;
    set(gca, 'YDir', 'normal');
    title(num2str(z));
    colormap(gca,'jet');
    subplot(232);
    imagesc(BMFrequency);
    axis image;
    axis off;
    set(gca, 'YDir', 'normal');
    colormap(gca, 'parula');
    subplot(233);
    imagesc(corrVal);
    axis image;
    axis off;
    set(gca, 'YDir', 'normal');
    colormap(gca,'jet');
    subplot(2,3,[4 6]);
    plot(z, max(corrVal(:)), 'or');
    hold on;
%     pause();
end

[~, z] = max(corrMaxVal);                                           % find axial position where the cross-correlation is maximized
n_section = mean(Reconimgtemp(:, :, (0:round(BMZres/res4)) + z), 3);% averaged corresponding averaged RI map
results.results.RISection = n_section;

%% Also do lateral correlation
corrVal = xcorr2(double(n_section > mean2(n_section)), double(Vq > mean2(Vq)));

[~, ind] = max(corrVal(:));
[x, y] = ind2sub(size(corrVal), ind);
x = x - size(Vq, 1);
y = y - size(Vq, 2);

Vq = circshift(Vq, [x, y]);
