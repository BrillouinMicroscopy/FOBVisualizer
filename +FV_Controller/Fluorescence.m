function callbacks = Fluorescence(model, view)
%% DATA Controller

    %% general panel
    set(view.Fluorescence.repetition, 'Callback', {@selectRepetition, model});
    set(view.Fluorescence.channels, 'Callback', {@selectChannel, model});

    callbacks = struct( ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    repetition.index = val;
    repetition.name = model.Fluorescence.repetitions{val};
    model.Fluorescence.repetition = repetition;
end

function selectChannel(src, ~, model)
    val = get(src, 'Value');
    model.Fluorescence.channel = val - 1;
end