function [idx, output_files] = read_output_files(animalNames, numAnimals, output_file_folder, suffix)
    % reads output files matching animalNames in output_file_folder
    filenames = {};
    output_files = {};
    output_filename = dir([output_file_folder '/*.csv']);
    for k=1:length(output_filename)
        filenames_cut = erase(output_filename(k).name, suffix);
        if ismember(filenames_cut, animalNames)
            filenames{k} = output_filename(k).name;
            output_files{k} = strcat(output_file_folder,'/',filenames{k});
        end
    end

    idx = [];
    for i=1:numAnimals
        idx = [idx find(strcmp(filenames, [animalNames{i} suffix]))];
    end
end

