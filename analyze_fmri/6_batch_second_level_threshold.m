%% Threshold second level fMRI results with two statistical significance levels

% Severi Santavirta & Yuhang Wu 15.5.2024

%% Threshold GPT-4V based results

% Define base paths
base_output = 'path/second_level_gpt/';
feature_dirs = dir(base_output);
feature_dirs = feature_dirs([feature_dirs.isdir]); % Keep only directories
feature_dirs = feature_dirs(~ismember({feature_dirs.name}, {'.', '..'}));

% Loop over each feature directory and process the second-level results
for i = 1:length(feature_dirs)
    feature = feature_dirs(i).name;
    feature_output = sprintf('%s%s/main_%s', base_output, feature, feature);
    spm_mat_file = fullfile(feature_output, 'SPM.mat');
    
    if exist(spm_mat_file, 'file')
        % Prepare the batch for the current feature
        matlabbatch{1}.spm.stats.results.spmmat = {spm_mat_file};
        matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{1}.spm.stats.results.conspec.contrasts = 1; % Contrast index
        matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
        matlabbatch{1}.spm.stats.results.conspec.thresh = 0.001;
        matlabbatch{1}.spm.stats.results.conspec.extent = 0;
        matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{1}.spm.stats.results.units = 1;
        matlabbatch{1}.spm.stats.results.export{1}.tspm.basename = sprintf('unc0001_pos_%s', feature);
        matlabbatch{2}.spm.stats.results.spmmat = {spm_mat_file};
        matlabbatch{2}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{2}.spm.stats.results.conspec.contrasts = 1; % Contrast index
        matlabbatch{2}.spm.stats.results.conspec.threshdesc = 'FWE';
        matlabbatch{2}.spm.stats.results.conspec.thresh = 0.05;
        matlabbatch{2}.spm.stats.results.conspec.extent = 0;
        matlabbatch{2}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{2}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{2}.spm.stats.results.units = 1;
        matlabbatch{2}.spm.stats.results.export{1}.tspm.basename = sprintf('FWE005_pos_%s', feature);

        % Set SPM to run in batch mode
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline', true);

        % Run the batch
        spm_jobman('run', matlabbatch);
    else
        fprintf('SPM.mat file not found for feature: %s\n', feature);
    end
end

%% Threshold human based results

base_output = 'path/second_level_human/';
feature_dirs = dir(base_output);
feature_dirs = feature_dirs([feature_dirs.isdir]); % Keep only directories
feature_dirs = feature_dirs(~ismember({feature_dirs.name}, {'.', '..'})); % Exclude . and ..

% Loop over each feature directory and process the second-level results
for i = 1:length(feature_dirs)
    feature = feature_dirs(i).name;
    feature_output = sprintf('%s%s/main_%s', base_output, feature, feature);
    spm_mat_file = fullfile(feature_output, 'SPM.mat');
    
    if exist(spm_mat_file, 'file')
        % Prepare the batch for the current feature
        matlabbatch{1}.spm.stats.results.spmmat = {spm_mat_file};
        matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{1}.spm.stats.results.conspec.contrasts = 1; % Contrast index
        matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
        matlabbatch{1}.spm.stats.results.conspec.thresh = 0.001;
        matlabbatch{1}.spm.stats.results.conspec.extent = 0;
        matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{1}.spm.stats.results.units = 1;
        matlabbatch{1}.spm.stats.results.export{1}.tspm.basename = sprintf('unc0001_pos_%s', feature);
        matlabbatch{2}.spm.stats.results.spmmat = {spm_mat_file};
        matlabbatch{2}.spm.stats.results.conspec.titlestr = '';
        matlabbatch{2}.spm.stats.results.conspec.contrasts = 1; % Contrast index
        matlabbatch{2}.spm.stats.results.conspec.threshdesc = 'FWE';
        matlabbatch{2}.spm.stats.results.conspec.thresh = 0.05;
        matlabbatch{2}.spm.stats.results.conspec.extent = 0;
        matlabbatch{2}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{2}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{2}.spm.stats.results.units = 1;
        matlabbatch{2}.spm.stats.results.export{1}.tspm.basename = sprintf('FWE005_pos_%s', feature);

        % Set SPM to run in batch mode
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');
        spm_get_defaults('cmdline', true);

        % Run the batch
        spm_jobman('run', matlabbatch);
    else
        fprintf('SPM.mat file not found for feature: %s\n', feature);
    end
end