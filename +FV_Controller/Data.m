function callbacks = Data(model, view)
%% DATA Controller

    %% general panel

    callbacks = struct( ...
        'closeFile', @()closeFile('', '', model) ...
    );
end

function closeFile(~, ~, model)
    if ~isempty(model.filename)
        model.log.log(['I/File: Closed file "' model.filepath model.filename '"']);
        model.log.write('');
    end
    model.reset();
end