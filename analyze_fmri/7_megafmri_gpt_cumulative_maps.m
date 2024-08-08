%% Calculate cumulative maps for social perception based on GPT and human based fMRI results

% Severi Santavirta 25.5.2024

%% SCRIPT

% Calculate the cumulative maps from p < 0.001, uncorrected results
files_gpt = find_files('path/second_level_gpt','spmT_0001_unc0001');
files_human = find_files('path/second_level_human','spmT_0001_unc0001');

for i = 1:size(files_gpt,1)
    fprintf('%d\n',i);

    % Read data
    human = spm_read_vols(spm_vol(files_human{i}));
    gpt = spm_read_vols(spm_vol(files_gpt{i}));

    % Binarize
    gpt(~isnan(gpt)) = 1;
    gpt(isnan(gpt)) = 0;
    human(~isnan(human)) = 1;
    human(isnan(human)) = 0;

    if(i == 1)
        gpt_cum = gpt;
        human_cum = human;
    else
        gpt_cum = gpt_cum + gpt;
        human_cum = human_cum + human;
    end
end

% Calculate a difference map
cum_diff = human_cum - gpt_cum;

% Save the maps
V = spm_vol(files_human{i});
V.fname = 'path/cumulative_gpt.nii';
spm_write_vol(V,gpt_cum);
V.fname = 'path/cumulative_human.nii';
spm_write_vol(V,human_cum);
V.fname = 'path/cumulative_difference.nii';
spm_write_vol(V,cum_diff);

% Calcalate the correlation between the cumulative maps.
img_gpt = spm_read_vols(spm_vol('path/cumulative_gpt.nii'));
img_human = spm_read_vols(spm_vol('path/cumulative_human.nii'));
img_gpt = img_gpt(:);
img_human = img_human(:);

% Select only in-brain voxels
mask = spm_read_vols(spm_vol('path/brainmask.nii'));
mask = logical(mask(:));
img_gpt = img_gpt(mask);
img_human = img_human(mask);
r = corr(img_gpt,img_human);
