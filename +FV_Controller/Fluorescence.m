function callbacks = Fluorescence(model, view)
%% DATA Controller

    %% general panel
    set(view.Fluorescence.repetition, 'Callback', {@selectRepetition, model});

    callbacks = struct( ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    model.Fluorescence.repetition = val - 1;
end