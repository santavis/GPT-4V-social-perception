"""
This is the third step in collecting image data.
At this stage, all csv files are combined into one file and the final file is cleaned and sorted.

Lauri Suominen 05.06.2025
"""

from pathlib import Path
import pandas as pd
import os

#%% Change parameters

# Round numbers
round_number = 1 # Dataset number (e.g. dataset_1)

# Basic path
basic_path = Path('path/ratings/data/gpt_4-1_data') # CHANGE

#%% Combines json files and txt files into one file. 
# This will create as amny combined files as you have extra rounds (e.g. combined_output_1_0.csv, combined_output_1-1.csv).

# Directory containing your CSV and text files
data_dir = basic_path / f'dataset_{round_number}'

# Get a list of all CSV files in the directory
csv_files = [f for f in os.listdir(data_dir) if f.endswith('.csv')]

for csv_file in csv_files:
    # Define the corresponding text file name
    text_file = csv_file.replace('.csv', '.txt')

    # Read the row names from the text file
    with open(os.path.join(data_dir, text_file), 'r') as f:
        row_names = [line.strip() for line in f]
    
    # Read the CSV file
    csv_path = os.path.join(data_dir, csv_file)
    
    # Check if the csv file is not empty and contains data
    if os.path.getsize(csv_path) > 0:
        try:
            df = pd.read_csv(csv_path)
            
            if df.empty:
                print(f'CSV file {csv_file} is empty after reading. Skipping this file.')
                continue
            
        except pd.errors.EmptyDataError:
            print(f'CSV file {csv_file} has no columns to parse. Skipping this file.')
            continue
        
    else:
        print(f'CSV file {csv_file} is empty. Skipping this file.')
    
    # Check if the number of row names is greater than the number of rows in the CSV
    if len(row_names) > len(df):
        # Calculate the number of empty rows needed
        num_empty_rows = len(row_names) - len(df)
        
        # Create a DataFrame with the empty rows
        empty_rows = pd.DataFrame(index=range(num_empty_rows), columns=df.columns)
        
        # Append the empty rows to the original DataFrame
        df = pd.concat([df, empty_rows], ignore_index=True)
    
    # Assign the row names to the DataFrame
    df.insert(0, 'imageNames', row_names)
    
    # Save the combined DataFrame to a new CSV file
    output_path = os.path.join(data_dir, 'combined_' + csv_file)
    df.to_csv(output_path, index=False)
    
    print(f"Combined file saved as {output_path}")

#%% This will create a merged csv file that combines all the combined files into one file.

# Directory containing your combined CSV files
data_dir = basic_path / f'dataset_{round_number}'

# Get a list of all combined CSV files and sort them alphabetically
combined_files = sorted([f for f in os.listdir(data_dir) if f.startswith('combined_') and f.endswith('.csv')])

# Read the first file
main_df = pd.read_csv(os.path.join(data_dir, combined_files[0]), index_col=0)

# Loop through the remaining combined files
for combined_file in combined_files[1:]:
    # Read the current file
    current_df = pd.read_csv(os.path.join(data_dir, combined_file), index_col=0)
    
    main_df = pd.concat([main_df, current_df])

# Save the merged DataFrame to a new CSV file
output_path = os.path.join(data_dir, f'merged_output_{round_number}.csv')
main_df.to_csv(output_path)

print(f"Merged file saved as {output_path}")

#%% This cleans and sorts the merged file and creates the final file.

# Read merged_output file
df = pd.read_csv(basic_path / f'dataset_{round_number}/merged_output_{round_number}.csv')

# Delete all rows which include one or more NaN-value
cleaned_df = df.dropna()

# Sort rows alphabetically by imageNames
sorted_df = cleaned_df.sort_values(by='imageNames')

# Save the cleaned merged DataFrame to new CSV file
output_path = basic_path / 'average' / 'input' / f'final_output_{round_number}.csv'
sorted_df.to_csv(output_path, index=False)

print(f'Clean data file saved as {output_path}')