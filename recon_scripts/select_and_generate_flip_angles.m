function [seq_uri, flip_xml_paths, flip_angles] = select_and_generate_flip_angles() 
    % === Set base directory ===
    % Define the base directory for JEMRIS by combining the user's home path with 'github/jemris'
    base_dir = fullfile(getenv('HOME'), 'github', 'jemris');
    % Define the path to the main simulation configuration file (simu.xml)
    simu_file = fullfile(base_dir, 'simu.xml');

    % === Define sequence directories ===
    % Create a mapping (key-value pairs) between category names and their corresponding directories
    sequence_dirs = containers.Map(...
        {'ps_xml', 'examples', 'angiosim'}, ...      % keys: categories of sequences
        { fullfile(base_dir, 'ps_xml'), ...          % directory for custom ps_xml sequences
          fullfile(base_dir, 'share', 'examples'), ... % directory for example sequences
          fullfile(base_dir, 'share', 'angiosim') });  % directory for angiosim sequences

    % === Prompt user to select category ===
    % Retrieve all category keys from the map
    category_keys = sequence_dirs.keys;
    fprintf('\nAvailable Sequence Categories:\n');
    % Print all available categories with numbering
    for i = 1:numel(category_keys)
        fprintf('  %d: %s\n', i, category_keys{i});
    end
    % Ask the user to input the number corresponding to their desired category
    category_idx = input('Select a sequence category (number): ');
    
    % Validate the user's input (must be within valid range)
    if category_idx < 1 || category_idx > numel(category_keys)
        error('Invalid category selection.');
    end

    % Get the name of the selected category and the corresponding directory path
    selected_category = category_keys{category_idx};
    seq_dir = sequence_dirs(selected_category);

    % === List available XML sequences in selected category ===
    % Find all .xml files in the chosen directory
    seq_files = dir(fullfile(seq_dir, '*.xml'));
    % If no XML sequence files are found, throw an error
    if isempty(seq_files)
        error('No XML sequence files found in selected category: %s', selected_category);
    end

    % Display all available XML sequence files to the user
    fprintf('\nAvailable Sequence Files in "%s":\n', selected_category);
    for i = 1:numel(seq_files)
        fprintf('  %2d: %s\n', i, seq_files(i).name);
    end
    % Ask the user to choose a specific XML file by index
    seq_idx = input('Select a sequence file (number): ');
    
    % Validate the user’s input (must correspond to one of the files)
    if seq_idx < 1 || seq_idx > numel(seq_files)
        error('Invalid sequence file selection.');
    end

    % Save the chosen sequence file name and full path (seq_uri is returned by the function)
    seq_name = seq_files(seq_idx).name;
    seq_uri = fullfile(seq_dir, seq_name);

    % === Update simu.xml to use selected sequence ===
    doc = xmlread(simu_file);
    root = doc.getDocumentElement();
    sequence_node = root.getElementsByTagName('sequence').item(0);
    sequence_node.setAttribute('name', erase(seq_name, '.xml'));
    sequence_node.setAttribute('uri', seq_uri);
    xmlwrite(simu_file, doc);
    
    fprintf('\n✅ simu.xml updated to use: %s\n', seq_uri);

    % === Prompt user for flip angles ===
    flip_input = input('\nEnter flip angles separated by spaces (e.g., "10 15 20"): ', 's');
    flip_angles = str2num(flip_input); %#ok<ST2NM>

    if isempty(flip_angles)
        error('❌ No valid flip angles entered.');
    end

    % === Generate modified XMLs for each flip angle ===
    [~, base_name, ~] = fileparts(seq_uri);
    output_prefix = fullfile(tempdir, base_name);
    flip_xml_paths = cell(numel(flip_angles), 1);

    for i = 1:numel(flip_angles)
        angle = flip_angles(i);
        angle_doc = xmlread(seq_uri);
        atomic_nodes = angle_doc.getElementsByTagName('ATOMICSEQUENCE');

        for j = 0:atomic_nodes.getLength-1
            node = atomic_nodes.item(j);
            if node.hasAttribute('Name') && strcmp(char(node.getAttribute('Name')), 'A1')
                child_nodes = node.getChildNodes();
                for k = 0:child_nodes.getLength-1
                    child = child_nodes.item(k);
                    if strcmp(char(child.getNodeName()), 'HARDRFPULSE')
                        child.setAttribute('FlipAngle', num2str(angle));
                    end
                end
            end
        end

        new_xml = sprintf('%s_flip%d.xml', output_prefix, angle);
        xmlwrite(new_xml, angle_doc);
        flip_xml_paths{i} = new_xml;

        fprintf('✅ Generated XML for FlipAngle = %d: %s\n', angle, new_xml);
    end
end
