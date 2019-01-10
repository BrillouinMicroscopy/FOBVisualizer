function handles = HelpAbout(parent, model)
%% OVERLAY View

    % build the GUI
    handles = initGUI(model, parent);
    
    set(parent, 'CloseRequestFcn', {@closeOverlay});    
end

function handles = initGUI(model, parent)
    xPos = 80;
    %% Program version
    version = sprintf('%d.%d.%d', model.programVersion.major, model.programVersion.minor, model.programVersion.patch);
    if ~strcmp('', model.programVersion.preRelease)
        version = [version '-' model.programVersion.preRelease];
    end
    labelStr = ['FOB Visualizer version ' version];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    jLabel.setFont(jLabel.getFont().deriveFont(20));
    javacomponent(jLabel, [10,110,380,30], parent);
    
    %% Commit
    labelStr = '<html>Commit:</html>';
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    javacomponent(jLabel, [10,80,290,20], parent);
    
    labelStr = ['<html><a href="">' model.programVersion.commit '</a></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, [xPos,80,290,20], parent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the label's tooltip
    hjLabel.setToolTipText('View the commit');

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)web([model.programVersion.link], '-browser'))
    
    %% Clean state of the repository
    
    if model.programVersion.cleanRepo
        str = 'Yes';
    else
        str = 'No';
    end
    labelStr = ['<html>Clean: ' str '</html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    javacomponent(jLabel, [375,80,60,20], parent);
    
    
    %% Author
    labelStr = '<html>Author:</html>';
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    javacomponent(jLabel, [10,50,300,20], parent);
    
    % Create and display the text label
    labelStr = ['<html><a href="">' model.programVersion.author ' &lt;' model.programVersion.email '&gt;' '</a></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, [xPos,50,310,20], parent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the label's tooltip
    hjLabel.setToolTipText('Write an email');

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)web(['mailto:' model.programVersion.email '?subject=FOB%20Visualizer']))

    %% Website
    labelStr = '<html>Website:</html>';
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    javacomponent(jLabel, [10,20,290,20], parent);
    
    % Create and display the text label
    labelStr = ['<html><a href="">' model.programVersion.website '</a></html>'];
    jLabel = javaObjectEDT('javax.swing.JLabel', labelStr);
    [hjLabel,~] = javacomponent(jLabel, [xPos,20,378,20], parent);

    % Modify the mouse cursor when hovering on the label
    hjLabel.setCursor(java.awt.Cursor.getPredefinedCursor(java.awt.Cursor.HAND_CURSOR));

    % Set the label's tooltip
    hjLabel.setToolTipText('Visit the FOB Visualizer website');

    % Set the mouse-click callback
    set(hjLabel, 'MouseClickedCallback', @(h,e)web([model.programVersion.website], '-browser'))
    
    %% set handles
    handles = struct(...
        'parent', parent ...
    );
end

function closeOverlay(source, ~)
    delete(source);
end