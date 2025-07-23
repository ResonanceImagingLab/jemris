function modify_simu()
    % === Define paths ===
    base_dir = fullfile(getenv('HOME'), 'github', 'jemris');
    simu_file = fullfile(base_dir, 'simu.xml');

    sequence_dirs = containers.Map(...
        {'ps_xml', 'examples', 'angiosim'}, ...
        { fullfile(base_dir, 'ps_xml'), ...
          fullfile(base_dir, 'share', 'examples'), ...
          fullfile(base_dir, 'share', 'angiosim') });

    sample_map = containers.Map(...
        {'2D sphere', '2D 2-spheres', '1D column', 'shepp-logan', 'brain'}, ...
        {'sample.h5', 'sample.h5', 'sample.h5', 'sample.h5', 'sample.h5'});

    % === Get sample selection ===
    sample_names = sample_map.keys;
    fprintf('\nAvailable Samples:\n');
    for i = 1:numel(sample_names)
        fprintf('%d: %s\n', i, sample_names{i});
    end
    sample_idx = input('Select a sample: ');
    sample_name = sample_names{sample_idx};
    sample_uri = fullfile(base_dir, sample_map(sample_name));

    % === Get sequence category and file ===
    category_keys = sequence_dirs.keys;
    fprintf('\nAvailable Sequence Categories:\n');
    for i = 1:numel(category_keys)
        fprintf('%d: %s\n', i, category_keys{i});
    end
    category_idx = input('Select a sequence category: ');
    seq_dir = sequence_dirs(category_keys{category_idx});
    
    seq_files = dir(fullfile(seq_dir, '*.xml'));
    if isempty(seq_files)
        error('No XML sequence files found in selected category.');
    end

    fprintf('\nAvailable Sequence Files:\n');
    for i = 1:numel(seq_files)
        fprintf('%d: %s\n', i, seq_files(i).name);
    end
    seq_idx = input('Select a sequence file: ');
    seq_name = seq_files(seq_idx).name;
    seq_uri = fullfile(seq_dir, seq_name);

    % === Load XML ===
    doc = xmlread(simu_file);
    root = doc.getDocumentElement();

    % === Update sample node ===
    sample_node = root.getElementsByTagName('sample').item(0);
    sample_node.setAttribute('name', sample_name);
    sample_node.setAttribute('uri', sample_uri);

    % === Update sequence node ===
    sequence_node = root.getElementsByTagName('sequence').item(0);
    sequence_node.setAttribute('name', erase(seq_name, '.xml'));
    sequence_node.setAttribute('uri', seq_uri);

    % === Write back to file ===
    xmlwrite(simu_file, doc);
    fprintf('\nUpdated simu.xml successfully.\n');
end
