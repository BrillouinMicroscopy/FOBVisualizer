function callbacks = ODT(model, view)
%% DATA Controller

    %% general panel
    set(view.ODT.repetition, 'Callback', {@selectRepetition, model});

    callbacks = struct( ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    model.ODT.repetition = val - 1;
end