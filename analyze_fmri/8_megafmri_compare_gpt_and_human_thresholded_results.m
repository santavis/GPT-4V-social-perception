%% Compare the feature specific fMRI results for social perception between GPT-4V and humans
% The following metrics for evaluating the reliability of GPT-4V derived brain response patterns are calculated
% correlation = Correlation between the unthresholded second level beta maps
% tp_norm = How many true positives out of all positive voxels (positive predictive value, PPV)
% fp_norm = How many false positives out of all positive voxels (false discovery rate, FDR)
% tn_norm = How many true negatives out of all negative voxels (negative predictive value, NPV)
% fn_norm = How many false negatives out of negative voxels (false omission rate, FOV)

% Severi Santavirta & Yuhang Wu, 8.8.2024

%% Loop over all analyzed social features

% Define directories
gpt_dir = 'path/second_level_gpt/';
human_dir = 'path/second_level_human/'; 

% List all created feature folders
created_folders_gpt = dir(gpt_dir);
created_folders_gpt = {created_folders_gpt([created_folders_gpt.isdir]).name};
created_folders_gpt(ismember(created_folders_gpt, {'.', '..'})) = [];

created_folders_human = dir(human_dir);
created_folders_human = {created_folders_human([created_folders_human.isdir]).name};
created_folders_human(ismember(created_folders_human, {'.', '..'})) = [];

% Find common features
common_features = intersect(created_folders_gpt, created_folders_human);

results = [];

% Loop over each common feature
for i = 1:length(common_features)
    feature = common_features{i};

    % Path to unthresholded results
    gpt_feature_path = fullfile(gpt_dir, feature, sprintf('main_%s', feature), 'beta_0001.nii');
    human_feature_path = fullfile(human_dir, feature, sprintf('main_%s', feature), 'beta_0001.nii');

    % Path to FWE corected results
    gpt_feature_path_fwe = fullfile(gpt_dir, feature, sprintf('main_%s', feature), sprintf('spmT_0001_FWE005_pos_%s.nii', feature));
    human_feature_path_fwe = fullfile(human_dir, feature, sprintf('main_%s', feature), sprintf('spmT_0001_FWE005_pos_%s.nii', feature));

    % Path to p < 0.001 uncorrected results
    gpt_feature_path_0001 = fullfile(gpt_dir, feature, sprintf('main_%s', feature), sprintf('spmT_0001_unc0001_pos_%s.nii', feature));
    human_feature_path_0001 = fullfile(human_dir, feature, sprintf('main_%s', feature), sprintf('spmT_0001_unc0001_pos_%s.nii', feature));
    
    % Check if both GPT and human files exist for FWE and 0.001
    if isfile(gpt_feature_path_fwe) && isfile(human_feature_path_fwe) && isfile(gpt_feature_path_0001) && isfile(human_feature_path_0001)
        
        % Load the second level unthresholde result images
        Vgpt = spm_vol(gpt_feature_path); 
        img_gpt = spm_read_vols(Vgpt);
        img_gpt = img_gpt(:);             % Vectorize 3D images
        brainmask = ~isnan(img_gpt);      % Define brainmask. Voxels outside the original mask are NaNs.
        img_gpt(~brainmask) = [];         %  Exclude those

        Vhuman = spm_vol(human_feature_path);
        img_human = spm_read_vols(Vhuman);
        img_human = img_human(:);
        img_human(~brainmask) = [];

        % Calculate the unthresholded correlation
        r = corr(img_gpt, img_human);

        % Load the second level result images for FWE threshold
        Vgpt_fwe = spm_vol(gpt_feature_path_fwe);
        img_gpt_fwe = spm_read_vols(Vgpt_fwe);
        img_gpt_fwe = img_gpt_fwe(:);
        img_gpt_fwe(~brainmask) = [];
        
        Vhuman_fwe = spm_vol(human_feature_path_fwe);
        img_human_fwe = spm_read_vols(Vhuman_fwe);
        img_human_fwe = img_human_fwe(:);
        img_human_fwe(~brainmask) = [];

        % Load the second level result images for uncorrected 0.001
        Vgpt_0001 = spm_vol(gpt_feature_path_0001);
        img_gpt_0001 = spm_read_vols(Vgpt_0001);
        img_gpt_0001 = img_gpt_0001(:);
        img_gpt_0001(~brainmask) = [];

        Vhuman_0001 = spm_vol(human_feature_path_0001);
        img_human_0001 = spm_read_vols(Vhuman_0001);
        img_human_0001 = img_human_0001(:);
        img_human_0001(~brainmask) = [];
        
        % True positives FWE
        tp_fwe = sum(~isnan(img_gpt_fwe) & ~isnan(img_human_fwe));
        
        % False positives FWE
        fp_fwe = sum(~isnan(img_gpt_fwe) & isnan(img_human_fwe));
        
        % False negatives FWE
        fn_fwe = sum(isnan(img_gpt_fwe) & ~isnan(img_human_fwe));
        
        % True negatives FWE
        tn_fwe = sum(isnan(img_gpt_fwe) & isnan(img_human_fwe));
        
        % Normalize by the appropriate sum for FWE
        tp_norm_fwe = tp_fwe / sum(~isnan(img_gpt_fwe)); % How many true positives out of all positive voxels
        fp_norm_fwe = fp_fwe / sum(~isnan(img_gpt_fwe)); % How many false positives out of all positive voxels
        tn_norm_fwe = tn_fwe / sum(isnan(img_gpt_fwe)); % How many true negatives out of all negative voxels
        fn_norm_fwe = fn_fwe / sum(isnan(img_gpt_fwe)); % How many false negatives out of negative voxels
        
        % True positives uncorrected 0.001
        tp_0001 = sum(~isnan(img_gpt_0001) & ~isnan(img_human_0001));
        
        % False positives uncorrected 0.001
        fp_0001 = sum(~isnan(img_gpt_0001) & isnan(img_human_0001));
        
        % False negatives uncorrected 0.001
        fn_0001 = sum(isnan(img_gpt_0001) & ~isnan(img_human_0001));
        
        % True negatives uncorrected 0.001
        tn_0001 = sum(isnan(img_gpt_0001) & isnan(img_human_0001));
        
        % Normalize by the appropriate sum for uncorrected 0.001
        tp_norm_0001 = tp_0001 / sum(~isnan(img_gpt_0001)); % How many true positives out of all positive voxels
        fp_norm_0001 = fp_0001 / sum(~isnan(img_gpt_0001)); % How many false positives out of all positive voxels
        tn_norm_0001 = tn_0001 / sum(isnan(img_gpt_0001)); % How many true negatives out of all negative voxels
        fn_norm_0001 = fn_0001 / sum(isnan(img_gpt_0001)); % How many false negatives out of negative voxels
        
        % Store results
        results = [results; {feature, r, tp_fwe, fp_fwe, tn_fwe, fn_fwe, tp_norm_fwe, fp_norm_fwe, tn_norm_fwe, fn_norm_fwe, tp_0001, fp_0001, tn_0001, fn_0001, tp_norm_0001, fp_norm_0001, tn_norm_0001, fn_norm_0001}];
    else
        warning('File not found for feature: %s', feature);
    end
end

% Convert results to table
results_table = cell2table(results, 'VariableNames', {'Feature', 'Correlation', 'TP_FWE', 'FP_FWE', 'TN_FWE', 'FN_FWE', 'TP_norm_FWE', 'FP_norm_FWE', 'TN_norm_FWE', 'FN_norm_FWE', 'TP_0001', 'FP_0001', 'TN_0001', 'FN_0001', 'TP_norm_0001', 'FP_norm_0001', 'TN_norm_0001', 'FN_norm_0001'});

% Save results as a CSV file
writetable(results_table, 'path/cor_and_threshold_results.csv');






