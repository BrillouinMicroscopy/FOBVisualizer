function callbacks = Fluorescence(model, view)
%% DATA Controller

    %% general panel
    set(view.Fluorescence.repetition, 'ValueChangedFcn', {@selectRepetition, model});
    set(view.Fluorescence.channels, 'ValueChangedFcn', {@selectChannel, model});

    callbacks = struct( ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    items = get(src, 'Items');
    repetition.index = find([items{:}] == val);
    repetition.name = model.Fluorescence.repetitions{repetition.index};
    model.Fluorescence.repetition = repetition;
end

function selectChannel(src, ~, model)
    val = get(src, 'Value');
    items = get(src, 'Items');
    model.Fluorescence.channel = find([items{:}] == val);
end