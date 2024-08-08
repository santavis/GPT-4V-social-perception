%% First level analyses of fMRI data with GPT derived regressors
% Batch the first level analysis over social features
%
% Severi Santavirta 2.3.2023
% Modified: Yuhang Wu 29.5.2024

clear; clc;

% Select only features where human-to-human-average correlation is > 0.5
filename = 'path/avgcorr_table.csv';
data = readtable(filename, 'ReadVariableNames', true);

firstColumn = data{:, 1};
firstColumn = lower(erase(firstColumn, '_'));

lastColumn = data{:, end};

indices = lastColumn > 0.5;
filteredFirstColumn = firstColumn(indices);

%%
% Directories
preproc_dir = 'path/preproc/'; % Path to preprocessed fMRI data (not shared publicly)
regressor_dir = 'path/regressors/gpt/'; % Path to regressor directory
first_level_dir = 'path/first_level_gpt/'; % Output directory
brainmask = 'path/brainmask.nii'; % Brainmask indicating in-brain voxels (not shared publicly)

all_subjects = {'sub-001';'sub-002';'sub-003';'sub-004';'sub-005';'sub-006';'sub-007';'sub-008';'sub-009';'sub-010';'sub-011';'sub-012';'sub-013';'sub-014';'sub-015';'sub-016';'sub-017';'sub-018';'sub-019';'sub-020';'sub-021';'sub-022';'sub-023';'sub-024';'sub-025';'sub-026';'sub-027';'sub-028';'sub-029';'sub-030';'sub-031';'sub-032';'sub-033';'sub-034';'sub-035';'sub-036';'sub-037';'sub-038';'sub-039';'sub-040';'sub-041';'sub-042';'sub-043';'sub-044';'sub-045';'sub-046';'sub-047';'sub-048';'sub-049';'sub-050';'sub-051';'sub-052';'sub-053';'sub-054';'sub-055';'sub-056';'sub-057';'sub-058';'sub-059';'sub-060';'sub-061';'sub-062';'sub-063';'sub-064';'sub-065';'sub-066';'sub-067';'sub-068';'sub-069';'sub-070';'sub-071';'sub-072';'sub-073';'sub-074';'sub-075';'sub-076';'sub-077';'sub-078';'sub-079';'sub-080';'sub-081';'sub-082';'sub-083';'sub-084';'sub-085';'sub-086';'sub-087';'sub-088';'sub-089';'sub-090';'sub-091';'sub-092';'sub-093';'sub-094';'sub-095';'sub-096';'sub-097';'sub-098';'sub-099';'sub-100';'sub-101';'sub-102';'sub-103';'sub-104'};
excluded_subjects = {'sub-002';'sub-012';'sub-015';'sub-068'};
subjects = setdiff(all_subjects,excluded_subjects);
bad_preproc = {'sub-007','sub-013','sub-100'}; % These subjects had glitches after preprocessing which affected their first level maps.
subjects = setdiff(subjects,bad_preproc);
clear all_subjects excluded_subjects

%% Loop over each feature in the filteredFirstColumn
for j = 1:length(filteredFirstColumn)
    feature = filteredFirstColumn{j}; % Extract the string from the cell
    
    feature_folder = sprintf('path/first_level_gpt/features/%s', feature);
    
    if ~exist(feature_folder, 'dir')
        mkdir(feature_folder);
    end
    
    %% Create and temporarily save subjectwise models
    X = cell(size(subjects,1),1);
    X_nui = cell(size(subjects,1),1);
    for i = 1:size(subjects,1)
        sub = subjects{i};

        reg_file = sprintf('%s/localizer_%s_gpt_regressors.mat',regressor_dir,sub);
        load(reg_file); % This loads 'R' and 'features'
        features = lower(erase(features, '_'));
        
        % Find the corresponding column index in 'features' for the current 'feature'
        colIndex = find(strcmp(features, feature));
        
        % Extract the relevant column from 'R'
        mdl = Rgpt(1:467, colIndex);
        R = mdl;
        names = feature; % Use the feature name as the name
        
        save(sprintf('%s/%s_model.mat',feature_folder,sub),'R','names');
    end

    %% Run SPM

    % Open parallel pool
    npool = 4;
    p = gcp('nocreate'); % If no pool, do not create new one.
    if(isempty(p))
        p = parpool(npool);
    end

    failed = 0;
    parfor i = 1:size(subjects,1)
        sub = subjects{i};
        outdir = sprintf('%s/%s/%s',first_level_dir,feature,sub);
        if(~exist(outdir,'dir'))
            mkdir(outdir);
        end
        con_file = sprintf('%s/con_0001.nii',outdir);
        if(~exist(con_file,'file'))
            spm_file = sprintf('%s/SPM.mat',outdir);
            if(exist(spm_file,'file'))
                %delete(spm_file);
            end
            model_file = sprintf('%s/%s_model.mat',feature_folder,sub);
            scans = cellstr(spm_select('ExtFPList',preproc_dir,sprintf('%s_task-localizer_space-MNI152NLin2009cAsym_desc-preproc_bold',sub),1:467));
            define_first_level_model(outdir,scans,model_file,brainmask);
            estimate_first_level_model(outdir);
        end
    end

    %% Gzip first level results
    betas = find_files(first_level_dir,'*beta_0002');
    masks = find_files(first_level_dir,'*mask');
    res = find_files(first_level_dir,'*ResMS');
    rpv = find_files(first_level_dir,'*RPV');
    spmf = find_files(first_level_dir,'*SPM');

    cellfun(@delete,betas)
    cellfun(@delete,masks)
    cellfun(@delete,res)
    cellfun(@delete,rpv)
    cellfun(@delete,spmf);
end

function define_first_level_model(outdir,scans,model_file,brainmask)

matlabbatch{1}.spm.stats.fmri_spec.dir = {outdir};
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'scans';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 2.6;
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 45; % 45 consecutive slices per TR
matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 23; % The reference slice (data is slice time corrected to the middle of TR and middle slice)
matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = scans; % Preprocessed EPIs
matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {}, 'orth', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {''};
matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {model_file}; % The whole model has been stored in MAT-file.
matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128; % High-pass filtering
matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
matlabbatch{1}.spm.stats.fmri_spec.volt = 1; % Do not model interactions
matlabbatch{1}.spm.stats.fmri_spec.global = 'None'; % No global normalization
matlabbatch{1}.spm.stats.fmri_spec.mthresh = -Inf; % Do not remove any voxel based on intensity comparison between mean image intensity
matlabbatch{1}.spm.stats.fmri_spec.mask = {brainmask}; % Mask voxels
matlabbatch{1}.spm.stats.fmri_spec.cvi = 'None'; % No serial correlation estimation

spm_jobman('initcfg');
spm_jobman('run', matlabbatch);

end
function estimate_first_level_model(outdir)

spm_file = sprintf('%s/SPM.mat',outdir);
matlabbatch{1}.spm.stats.fmri_est.spmmat = {spm_file};
matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;

spm_jobman('initcfg');
spm_jobman('run',matlabbatch)

end
function files = find_files(directory,filter)

if(nargin < 2)
    msg = sprintf('You need to specify two input arguments: First, the directory under which you want to perform the search, and second the filter.\n\nFor example: files = find_files(''/scratch/shared/toolbox/spm12'',''*.m'')');
    error(msg);
end

files = get_filenames(directory,filter);
if(~isempty(files))
    dirs = zeros(length(files),1);
    for f = 1:length(files)
        dirs(f) = isdir(files{f});
    end
    dir_idx = find(dirs);
    files(dir_idx) = [];
end

d = dir(directory);
isub = [d(:).isdir]; %# returns logical vector
all_subfolders = {d(isub).name}';
all_subfolders(ismember(all_subfolders,{'.','..'})) = [];

all_subfolders = strcat(directory,'/',all_subfolders);

for i = 1:length(all_subfolders)
    a = find_files(all_subfolders{i},filter);
    if(~isempty(a))
        files = [files;a];
    end
end

end
