"""
This is the sixth and last step in collecting image data.
This will calculate the average of all possible combinations of your final output files.

Lauri Suominen 05.06.2025
"""

import os
import pandas as pd
import glob
from itertools import combinations

#%% Change parameters

# Number of files
number_of_files = 5

# Input and output directory
input_dir = 'path/raitings/data/gpt_data/average/input'
output_dir = 'path/raitings/data/gpt_data/average/all_averages'

#%% Script

# Reading all CSV files from directory
csv_files = glob.glob(os.path.join(input_dir, "*.csv"))
csv_files.sort()

# Check nukber of csv files
assert len(csv_files) == number_of_files

# Average function
def process_files(files):
    dfs = []    
    first_column_data = []

    for i, file in enumerate(files):
        df = pd.read_csv(file)
    
        if i == 0:  # Take first file first column
            first_column_data = df.iloc[:, 0].reset_index(drop=True)
    
        # Remove first column other files
        df = df.iloc[:, 1:]
    
        # Adding others values to matrix
        dfs.append(df)
        
    # Concatenate all dataframes row-wise (aligning rows)        
    combined_df = pd.concat(dfs, axis=0)
    
    # Calculate the mean across all the columns (files)
    average_df = combined_df.groupby(combined_df.index).mean()
    
    # Combine the first column with the averaged values
    final_df = pd.concat([first_column_data, average_df], axis=1)

    return final_df

loop_end_num = number_of_files + 1
loop_start_num = loop_end_num - number_of_files

# Loop over 2, 3, 4, and 5 files
for n_files in range(loop_start_num, loop_end_num):
    # Generate all combinations of n_files from the list of CSV files
    for selected_files in combinations(csv_files, n_files):
        result_df = process_files(selected_files)
        
        # Create the output filename
        # Get the file indices (+1 to make them 1-based)
        selected_files_indices = [csv_files.index(f) + 1 for f in selected_files]
        
        # Join the indices into a string separated by underscores
        selected_files_str = "_".join(map(str, selected_files_indices))
        
        # Create the filename with n_files and the selected files' indices
        output_filename = f'output_average_{n_files}_files_{selected_files_str}.csv'
        
        # Save the result to the output directory
        result_df.to_csv(os.path.join(output_dir, output_filename), index=False)

        print(f"Average values for {n_files} files ({selected_files_indices}) have been saved to {output_filename}.")
        