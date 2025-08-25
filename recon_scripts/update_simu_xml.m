function update_simu_xml(xml_path)
    % Updates simu.xml to point to the given xml_path
    doc = xmlread('simu.xml');
    root = doc.getDocumentElement();
    sequence_node = root.getElementsByTagName('sequence').item(0);

    % Extract file name for 'name' attribute
    [~, name, ~] = fileparts(xml_path);

    sequence_node.setAttribute('name', name);
    sequence_node.setAttribute('uri', xml_path);

    xmlwrite('simu.xml', doc);
end
