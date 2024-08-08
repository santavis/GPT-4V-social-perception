%% Second level analyses of fMRI data with human derived regressors
% Batch the second level analysis over social features
%
% Severi Santavirta 2.3.2023
% Modified: Yuhang Wu 31.5.2024

% Define the directories
base_indir = 'path/first_level_human/'; % First level directory
base_output = 'path/second_level_human/'; % Output dir
mask = 'path/brainmask.nii'; % Brainmask indicating in-brain voxels (not shared publicly)

%% SCRIPT

all_subjects = {'sub-001';'sub-002';'sub-003';'sub-004';'sub-005';'sub-006';'sub-007';'sub-008';'sub-009';'sub-010';'sub-011';'sub-012';'sub-013';'sub-014';'sub-015';'sub-016';'sub-017';'sub-018';'sub-019';'sub-020';'sub-021';'sub-022';'sub-023';'sub-024';'sub-025';'sub-026';'sub-027';'sub-028';'sub-029';'sub-030';'sub-031';'sub-032';'sub-033';'sub-034';'sub-035';'sub-036';'sub-037';'sub-038';'sub-039';'sub-040';'sub-041';'sub-042';'sub-043';'sub-044';'sub-045';'sub-046';'sub-047';'sub-048';'sub-049';'sub-050';'sub-051';'sub-052';'sub-053';'sub-054';'sub-055';'sub-056';'sub-057';'sub-058';'sub-059';'sub-060';'sub-061';'sub-062';'sub-063';'sub-064';'sub-065';'sub-066';'sub-067';'sub-068';'sub-069';'sub-070';'sub-071';'sub-072';'sub-073';'sub-074';'sub-075';'sub-076';'sub-077';'sub-078';'sub-079';'sub-080';'sub-081';'sub-082';'sub-083';'sub-084';'sub-085';'sub-086';'sub-087';'sub-088';'sub-089';'sub-090';'sub-091';'sub-092';'sub-093';'sub-094';'sub-095';'sub-096';'sub-097';'sub-098';'sub-099';'sub-100';'sub-101';'sub-102';'sub-103';'sub-104'};
excluded_subjects = {'sub-002';'sub-012';'sub-015';'sub-068'};
subjects = setdiff(all_subjects,excluded_subjects);
bad_preproc = {'sub-007','sub-013','sub-100'}; %%%%%% These subjects had glitches after preprocessing which affected their first level maps.
subjects = setdiff(subjects,bad_preproc);
clear all_subjects excluded_subjects

%% Main effect
% Loop through each feature folder and perform second level analysis
created_folders = dir(base_indir);
created_folders = {created_folders([created_folders.isdir]).name};
created_folders(ismember(created_folders, {'.', '..'})) = [];

for j = 1:length(created_folders)
    feature = created_folders{j}; % Extract the feature name
    feature_indir = fullfile(base_indir, feature);
    feature_output = fullfile(base_output, feature);
    
    if ~exist(feature_output, 'dir')
        mkdir(feature_output);
    end
    
    % Define the second level analysis parameters
    contrast_image = 'beta_0001.nii';
    outdir = sprintf('%s/main_%s', feature_output, feature);
    
    % Perform second level analysis
    out = define_second_level_main_effects_model(contrast_image, subjects, mask, feature_indir, outdir);
    out = estimate_second_level_model(outdir);
    out = define_contrasts_main_effect_models(outdir, sprintf('main_%s', feature));
end

%% Functions

function out = define_second_level_main_effects_model(contrast_image,subjects,brainmask,indir,outdir)
% Anlayze maain affects without covariates based on input contrasts and
% subjects
    
    try
        scans=fullfile(indir,subjects,contrast_image);

        % Define the model
        matlabbatch{1}.spm.stats.factorial_design.dir = {outdir};
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = scans;
        matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {}); % No covariates
        matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {}); % No covariates
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1; % No threshold masking
        matlabbatch{1}.spm.stats.factorial_design.masking.im = 0; % No implicit masking
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {brainmask}; % Use external brain maks
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1; % No global calculation
        matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1; % No grand mean scaling
        matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1; % No global normalization
        spm_jobman('initcfg');
        spm_jobman('run', matlabbatch);
        
        out = 1;
    catch
        out = 0;
    end
end
function out = define_contrasts_main_effect_models(outdir,contrast)
    try
        spm_file = sprintf('%s/SPM.mat',outdir);
        matlabbatch{1}.spm.stats.con.spmmat = {spm_file};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = sprintf('%s+',contrast);
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.convec = [1];
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = sprintf('%s-',contrast);
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.convec = [-1];
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch)

        out = 1;
    catch
        out = 0;
    end
end
function out = estimate_second_level_model(outdir)
    try
        spm_file = sprintf('%s/SPM.mat',outdir);
        matlabbatch{1}.spm.stats.fmri_est.spmmat = {spm_file};
        matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
        matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
        spm_jobman('initcfg');
        spm_jobman('run',matlabbatch)
        
        out = 1;
    catch
        out = 0;
    end
end

