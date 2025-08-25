function [seq_uri, flip_xml_paths, flip_angles] = select_and_generate_flip_angles() 

    % Set up command line interface (CLI)
    % === Set base directory ===
    base_dir = fullfile(getenv('HOME'), 'github', 'jemris'); % Define the base JEMRIS directory inside home folder
    simu_file = fullfile(base_dir, 'simu.xml');

    % === Define sequence directories ===
    sequence_dirs = containers.Map( ...   
        {'ps_xml', 'examples', 'angiosim'}, ...
        { fullfile(base_dir, 'ps_xml'), ... % Path to directory
          fullfile(base_dir, 'share', 'examples'), ...
          fullfile(base_dir, 'share', 'angiosim') });

    % === Prompt user to select category ===
    category_keys = sequence_dirs.keys;
    % List all available categories (ps_xml, examples, angiosim)
    % Each category is given an index so the user can select it by number
    fprintf('\nAvailable Sequence Categories:\n');  
    for i = 1:numel(category_keys)
        fprintf('  %d: %s\n', i, category_keys{i});
    end
    category_idx = input('Select a sequence category (number): ');

    if category_idx < 1 || category_idx > numel(category_keys)
        error('Invalid category selection.');
    end

    selected_category = category_keys{category_idx};
    seq_dir = sequence_dirs(selected_category);

    % === List available XML sequences in selected category ===
    seq_files = dir(fullfile(seq_dir, '*.xml'));  % Search the chosen directory for all files ending in .xml
    if isempty(seq_files)
        error('No XML sequence files found in selected category: %s', selected_category);
    end

    fprintf('\nAvailable Sequence Files in "%s":\n', selected_category); % Print out a numbered list of all available XML files in this directory
    for i = 1:numel(seq_files)
        fprintf('  %2d: %s\n', i, seq_files(i).name);
    end
    seq_idx = input('Select a sequence file (number): '); % Prompt the user to select one XML file by its number

    if seq_idx < 1 || seq_idx > numel(seq_files)
        error('Invalid sequence file selection.');
    end

    % Store the chosen category and retrieve its directory path
    seq_name = seq_files(seq_idx).name; % Save the name of the chosen XML file
    seq_uri = fullfile(seq_dir, seq_name); % Construct the full path to that file (this is the seq_uri output of the function)

    % === Update simu.xml to use selected sequence ===
    doc = xmlread(simu_file); % Read the simu.xml file into a DOM object
    root = doc.getDocumentElement();
    sequence_node = root.getElementsByTagName('sequence').item(0); % Find the <sequence> element inside simu.xml
    sequence_node.setAttribute('name', erase(seq_name, '.xml')); % Update its "name" attribute to the chosen sequence name (without .xml extension)
    sequence_node.setAttribute('uri', seq_uri); % Update its "uri" attribute to the full path of the chosen XML file
    xmlwrite(simu_file, doc);
    
    fprintf('\n✅ simu.xml updated to use: %s\n', seq_uri);

    % === Prompt user for flip angles ===
    flip_input = input('\nEnter flip angles separated by spaces (e.g., "10 15 20"): ', 's');
    flip_angles = str2num(flip_input); % Convert the string of numbers into a numeric array

    if isempty(flip_angles)
        error('❌ No valid flip angles entered.');
    end

    % === Generate modified XMLs for each flip angle ===
    [~, base_name, ~] = fileparts(seq_uri); % Extract base name of the selected XML file
    output_prefix = fullfile(tempdir, base_name);
    flip_xml_paths = cell(numel(flip_angles), 1);

    for i = 1:numel(flip_angles) % Loop through each flip angle provided by the user
        angle = flip_angles(i);
        angle_doc = xmlread(seq_uri);
        atomic_nodes = angle_doc.getElementsByTagName('ATOMICSEQUENCE'); % Get all <ATOMICSEQUENCE> nodes

        for j = 0:atomic_nodes.getLength-1
            node = atomic_nodes.item(j);
            if node.hasAttribute('Name') && strcmp(char(node.getAttribute('Name')), 'A1') % Look for the atomic sequence with Name="A1"
                child_nodes = node.getChildNodes(); % Get all child nodes of this atomic sequence
                for k = 0:child_nodes.getLength-1
                    child = child_nodes.item(k);
                    if strcmp(char(child.getNodeName()), 'HARDRFPULSE') % If the child node is a <HARDRFPULSE>, update its FlipAngle
                        child.setAttribute('FlipAngle', num2str(angle));
                    end
                end
            end
        end

        new_xml = sprintf('%s_flip%d.xml', output_prefix, angle); % Define the filename for the new XML (includes flip angle in name)
        xmlwrite(new_xml, angle_doc); % Save the modified XML to file
        flip_xml_paths{i} = new_xml;

        fprintf('✅ Generated XML for FlipAngle = %d: %s\n', angle, new_xml); % Print confirmation message for this flip angle
    end
end
