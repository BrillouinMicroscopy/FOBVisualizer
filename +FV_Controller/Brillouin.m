function callbacks = Brillouin(model, view)
%% DATA Controller

    %% general panel
    set(view.Brillouin.repetition, 'Callback', {@selectRepetition, model});

    callbacks = struct( ...
    );
end

function selectRepetition(src, ~, model)
    val = get(src, 'Value');
    model.Brillouin.repetition = val - 1;
end