"""
This is the fourth step in collecting video data. 
This step generates a CSV file from the json file created in the previous step.
It also checks for missing ratings for videos and copies them to a new folder for an extra run of step three.

Lauri Suominen 05.06.2025
"""

from pathlib import Path
import json
import pandas as pd
import numpy as np
import re
import shutil
import os

#%% Change parameters

# This parameter is the number of your dataset you are currently working with
round_number = 1 # Dataset number (e.g. dataset_1)

# If you have extra round(s) in your dataset, change this value
extra_round = 0 # This value is default

# Basic path
basic_path = Path('path/ratings/data/gpt_4-1_data') # CHANGE

# Image source folder and next round target folder
source_folder = 'path/stimulus_frames' # CHANGE
target_folder = f'path/stimulus_frames_round_{round_number}_{extra_round}' # CHANGE

#%% Convert json file to csv file

file_path = basic_path / f'dataset_{round_number}/output_{round_number}_{extra_round}.json'

# Function to read a JSON string and extract the desired content
def load_and_extract(file_path):
    extracted_contents = []
    
    # Open the file and read line by line
    with open(file_path, 'r', encoding='utf-8') as file:
        json_object = ''
        for line in file:
            json_object += line.strip()
            if line.startswith('}'):  # Checks if the line indicates the end of a JSON object
                try:
                    # Parse the JSON object
                    data = json.loads(json_object)
                    # Reset the JSON object string
                    json_object = ''
                    # Extract the desired content from the parsed JSON object
                    if 'error' in data:  
                        content = data['error'].get('message', '')
                        extracted_contents.append(content)
                    elif 'choices' in data and len(data['choices']) > 0:
                        content = data['choices'][0]['message']['content']
                        extracted_contents.append(content)
                except json.JSONDecodeError as e:
                    print(f"Error decoding JSON: {e}")
                    # Reset the JSON object string in case of a decoding error
                    json_object = ''

    return extracted_contents

# Load and extract the contents of the JSON file
contents = load_and_extract(file_path)

# Function for parsing individual text content
def parse_content(content):
    # Check if the content is unavailable
    if content.strip().startswith("{I'm sorry}"):
        return {"Data Unavailable": np.nan}

    # Split the content string into lines
    lines = content.split('\n')
    
    # Prepare a dictionary to hold the feature-score pairs
    feature_scores = {}
    
    # Define a regular expression to match lines with features and scores
    line_regex = re.compile(r'^(.+?)[\t\|\:,\s]+\s*(\d+)\s*(?:\(\s*[^)]*\))?\s*$')
    
    for line in lines:
        match = line_regex.match(line.strip())
        if match:
            feature, score = match.groups()
            try:
                # Convert score to float and store in the dictionary
                feature_scores[feature.strip()] = float(score)
            except ValueError:
                # Handle the case where conversion fails
                feature_scores[feature.strip()] = np.nan
    
    return feature_scores

# Parse all extracted content
parsed_contents = [parse_content(content) for content in contents]

# Create a DataFrame from the results
df = pd.DataFrame(parsed_contents)

# Save the DataFrame as a CSV file
df.to_csv(basic_path / f'dataset_{round_number}/output_{round_number}_{extra_round}.csv', index=False)

#%% Check missing images and copy these to new folder 'target_folder'

# Finds rows where all values are missing (NaN) and stores their indices as a list
empty_rows = df.index[df.isnull().all(axis=1)].tolist()

# Finds rows with even one missing values (NaN) and stores their indices as a list
nan_rows = df.index[df.isnull().any(axis=1)].tolist()

# Crate a new DataFrame containing only those rows with at least one missing value
nan_rows_df = df[df.isnull().any(axis=1)]

# Finds columns with at least one missing value
columns_with_null = df.columns[df.isnull().any()].tolist()

# Finds columns with all values missing
all_null_columns = df.columns[df.isnull().all()].tolist()

# Open a file and reads all lines into a lis
with open(basic_path / f'dataset_{round_number}/output_{round_number}_{extra_round}.txt', 'r') as file:
    lines = file.readlines()
 
# Extracts row data from rows whose indexes are completely empty rows
empty_rows_content = [lines[i] for i in empty_rows]

# Copy files whose names are found in the empty_rows_content list
for file_name in empty_rows_content:
    file_name = file_name.strip() # Removes line breaks and whitespace characters from the filename
    source_path = os.path.join(source_folder, file_name)
    target_path = os.path.join(target_folder, file_name)
    
    # If the source file is found, it is copied to the target folder
    if os.path.exists(source_path):
        shutil.copytree(source_path, target_path)
        print(f"'{file_name}' has been copied to '{target_folder}'.")
    else:
        print(f"'{file_name}' not found in '{source_folder}'.")
