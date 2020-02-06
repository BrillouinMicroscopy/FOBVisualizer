function str = iconString(filepath)
    iconFile = urlencode(fullfile(filepath));
    iconUrl1 = strrep(['file:/' iconFile],'\','/');
    scale = BE_SharedFunctions.getScalingValue();
    width = scale*20;
    height = scale*20;
    str = ['<html><img src="' iconUrl1 '" height="' sprintf('%1.0f', height) '" width="' sprintf('%1.0f', width) '"/></html>'];
end