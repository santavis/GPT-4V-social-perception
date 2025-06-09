%% Calculate cumulative maps for social perception based on GPT4 and human based fMRI results

% Severi Santavirta 9.6.2025

%% SCRIPT

% Calculate the cumulative maps from p < 0.001, uncorrected results
files_gpt = find_files('/path/second_level_gpt','spmT_0001_unc0001'); % Input GPT results
files_human = find_files('/path/second_level_human','spmT_0001_unc0001'); % Input human results

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
V.fname = '/path/cumulative_gpt4.nii';
spm_write_vol(V,gpt_cum);
V.fname = '/path/cumulative_human_gpt4.nii';
spm_write_vol(V,human_cum);
V.fname = '/path/cumulative_difference_gpt4.nii';
spm_write_vol(V,cum_diff);

% Calculate the correlation between the cumulative maps.
img_gpt = spm_read_vols(spm_vol('/path/cumulative_gpt4.nii'));
img_human = spm_read_vols(spm_vol('/path/cumulative_human_gpt4.nii'));
img_gpt = img_gpt(:);
img_human = img_human(:);

% Select only in-brain voxels
mask = spm_read_vols(spm_vol('/path/megafmri_localizer_gm_mask_3mm.nii'));
mask = logical(mask(:));
img_gpt = img_gpt(mask);
img_human = img_human(mask);

% Calculate spatial correlation between the cumulative maps
r = corr(img_gpt,img_human);
