function update_simu_xml(xml_path) % Updates simu.xml to point to the given xml_path
    doc = xmlread('simu.xml'); % Load simu.xml into a DOM (Document Object Model) object
    root = doc.getDocumentElement(); % Get the root element of simu.xml
    sequence_node = root.getElementsByTagName('sequence').item(0); % Locate the <sequence> element (assumes first one is the target)

    % Extract file name for 'name' attribute
    [~, name, ~] = fileparts(xml_path);

    % Update the <sequence> element attributes:
    % "name" = base file name (no extension)
    % "uri"  = full path to the sequence XML
    sequence_node.setAttribute('name', name);
    sequence_node.setAttribute('uri', xml_path);

    xmlwrite('simu.xml', doc); % Write the modified DOM object back to simu.xml
end
