"""
This is the second step in the process of collecting video data.
In this step, the audio file is converted to a txt file.

Lauri Suominen 05.06.2025
"""

import os
import time
from openai import OpenAI
import pandas as pd

#%% Change parameters

# Input folder containing the audio file
folder_path = "path/stimulus_frames_new" # CHANGE

#%% Converting an audio file to a text file

# Configure the OpenAI client to use the Whisper model
client = OpenAI(
        api_key= 'Bearer YOUR-API-KEY')

# Transcribe a single audio file using OpenAI's Whisper model and return a text output
def transcribe_audio(file_path):
    """ Transcribe audio using Whisper and save the transcription to a text file. """
    with open(file_path, "rb") as audio_file:
        transcript = client.audio.transcriptions.create(
            model="whisper-1", 
            file=audio_file,
            response_format="text"
        )
    return transcript

# Process all MP3 files in a folder and transcribe them into text files
def process_audio_files(folder_path, processed_file='audio_processed.txt'):
    start_time = time.time()
    
    # Read the list of subfolders already processed
    try:
        with open(processed_file, 'r') as f:
            processed_files = [line.strip() for line in f]
    except FileNotFoundError:
        processed_files = []

    processed_count = 0
    
    # Loop through all subfolders in a folder
    for subfolder in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, subfolder)
        
        # Only new subfolders are processed
        if os.path.isdir(subfolder_path) and subfolder not in processed_files:            
            for filename in os.listdir(subfolder_path):
                file_path = os.path.join(subfolder_path, filename)
                
                # Searching for MP3 files
                if filename.lower().endswith('.mp3'):
                    # Transcribe the file
                    transcript_text = transcribe_audio(file_path)          
                    
                    # Save transcription as a text file in the same folder
                    text_file_path = file_path.replace('.mp3', '.txt')  # Change the file extension to .txt
                    with open(text_file_path, 'w', encoding='utf-8') as text_file:
                        text_file.write(transcript_text)
                    
                    # Save progress
                    with open(processed_file, 'a', encoding='utf-8') as f:
                        f.write(subfolder + '\n')
                    
                    processed_count += 1  # Increment processed count
                    print(f"Transcribed and saved: {file_path}")
                
    total_time = time.time() - start_time
    print(f"Processed {processed_count} files, total elapsed time: {total_time:.2f} ses.")
    
# Start processing
process_audio_files(folder_path)

#%% Load transcripts from a folder structure into a Pandas DataFrame

# Load all transcripts into a DataFrame
def load_transcriptions_to_dataframe(folder_path):
    data = []
    # Loop through all subfolders
    for subfolder in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, subfolder)
        if os.path.isdir(subfolder_path):
            for filename in os.listdir(subfolder_path):
                if filename.lower().endswith('.txt'):
                    file_path = os.path.join(subfolder_path, filename)
                    with open(file_path, 'r', encoding='utf-8') as file:
                        transcription = file.read()
                    data.append({'file_name': filename, 'transcription': transcription})
                    
    # Return a DataFrame with filenames and transcripts
    df = pd.DataFrame(data)
    return df

# Load the transcripts into a DataFrame variable
df_transcriptions = load_transcriptions_to_dataframe(folder_path)
