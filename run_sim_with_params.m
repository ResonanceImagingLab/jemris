function run_sim_with_params()
% Configure sequence and sample parameters before running JEMRIS

    % === Define base paths ===
    base_dir = fullfile(getenv('HOME'), 'github', 'jemris');
    simu_path = fullfile(base_dir, 'simu.xml');
    last_seq_file = fullfile(base_dir, 'last_sequence.txt');

    % === Read and parse simu.xml ===
    doc = xmlread(simu_path);
    sim_node = doc.getDocumentElement();

    % Get sample and sequence info for display
    sample_node = sim_node.getElementsByTagName('sample').item(0);
    sample_name = char(sample_node.getAttribute('name'));

    sequence_node = sim_node.getElementsByTagName('sequence').item(0);
    sequence_name = char(sequence_node.getAttribute('name'));
    sequence_uri = char(sequence_node.getAttribute('uri'));

    fprintf('\n--- Loaded simu.xml ---\n');
    fprintf('Simu.xml:     %s\n', simu_path);
    fprintf('Sample Name:  %s\n', sample_name);
    fprintf('Sequence:     %s\n', sequence_name);
    fprintf('Sequence URI: %s\n\n', sequence_uri);

    % === Sample Parameters ===
    fprintf('\n--- Sample Parameters ---\n');
    sample_fields = {'T1', 'T2', 'T2star', 'M0', 'CS', 'Radius', 'dx', 'dy'};
    sample_defaults = struct('T1', '1000', 'T2', '100', 'T2star', '100', ...
                             'M0', '1', 'CS', '0', 'Radius', '50', 'dx', '1', 'dy', '1');

    for i = 1:length(sample_fields)
        field = sample_fields{i};

        if sample_node.hasAttribute(field)
            current = char(sample_node.getAttribute(field));
        else
            current = sample_defaults.(field);
        end

        user_input = input(sprintf('%s [%s]: ', field, current), 's');

        if ~isempty(user_input)
            sample_node.setAttribute(field, user_input);
        elseif ~isempty(current)
            sample_node.setAttribute(field, current);
        end
    end

    % === Save changes to simu.xml ===
    xmlwrite(simu_path, doc);
    fprintf('\n✅ Updated simu.xml with selected parameters.\n');
    fprintf('You can now run the simulation using:\n');
    fprintf('  ./src/jemris ../simu.xml\n\n');
end
