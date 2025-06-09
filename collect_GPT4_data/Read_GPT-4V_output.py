# -*- coding: utf-8 -*-
"""
Read the .json file of the GPT output

@author: 吴雨航 Yuhang Wu
@Email: wuyuhang@ruc.edu.cn 
First created: 4/3/2024 
Last modified: 21/4/2024

"""


import json

file_path = 'YOUR-JSON-FILE'

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


contents = load_and_extract(file_path)

#%% Convert into dataframe

import pandas as pd
import numpy as np
import re

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

parsed_contents = [parse_content(content) for content in contents]

df = pd.DataFrame(parsed_contents)

# df.to_csv('YOUR_FILE.csv', index=False)

#%% deal with the NAN
import pandas as pd
df = pd.read_csv('YOUR_FILE.csv')
df = df.dropna(axis=1, how='all')

empty_rows = df.index[df.isnull().all(axis=1)].tolist()
nan_rows = df.index[df.isnull().any(axis=1)].tolist()
nan_rows_df = df[df.isnull().any(axis=1)]

# columns_with_null = df.columns[df.isnull().any()].tolist()
# all_null_columns = df.columns[df.isnull().all()].tolist()

with open('processed.txt', 'r') as file:
    lines = file.readlines()

empty_rows_content = [lines[i] for i in empty_rows]

import shutil
import os

source_folder = 'YOUR_SOURCE_FOLDER'
target_folder = 'YOUR_TARGET_FOLDER'


for file_name in empty_rows_content:
    file_name = file_name.strip()
    source_path = os.path.join(source_folder, file_name)
    target_path = os.path.join(target_folder, file_name)
    
    if os.path.exists(source_path):
        shutil.copy(source_path, target_path)
        print(f"'{file_name}' has been copied to '{target_folder}'.")
    else:
        print(f"'{file_name}' not found in '{source_folder}'.")
