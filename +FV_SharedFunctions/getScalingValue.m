function scale = getScalingValue()
    screenSize = get(0,'ScreenSize');
    jScreenSize = java.awt.Toolkit.getDefaultToolkit.getScreenSize;
    scale = jScreenSize.width/screenSize(3);
end