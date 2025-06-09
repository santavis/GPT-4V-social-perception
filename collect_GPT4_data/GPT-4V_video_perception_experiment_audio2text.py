# -*- coding: utf-8 -*-
"""
Note: Run it before [GPT-4V video perception experiment.py]

Batch process of transcribing audio into text using Whisper model

Ref: https://platform.openai.com/docs/guides/speech-to-text/quickstart

@author: 吴雨航 Yuhang Wu
@Email: wuyuhang@ruc.edu.cn 
First created: 18/4/2024 
Last modified: 15/5/2024

"""

import os
import time
from openai import OpenAI

client = OpenAI()

def transcribe_audio(file_path):
    """ Transcribe audio using Whisper and save the transcription to a text file. """
    with open(file_path, "rb") as audio_file:
        transcript = client.audio.transcriptions.create(
            model="whisper-1", 
            file=audio_file,
            response_format="text"
        )
    return transcript

def process_audio_files(folder_path, processed_file='audio_processed.txt'):
    start_time = time.time()
    
    try:
        with open(processed_file, 'r') as f:
            processed_files = [line.strip() for line in f]
    except FileNotFoundError:
        processed_files = []

    processed_count = 0
    for subfolder in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, subfolder)
        if os.path.isdir(subfolder_path) and subfolder not in processed_files:            
            for filename in os.listdir(subfolder_path):
                file_path = os.path.join(subfolder_path, filename)
                
                if filename.lower().endswith('.mp3'):
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


folder_path = "YOUR-FOLDER-PATH"

process_audio_files(folder_path)

#%% read and check the file

import os
import pandas as pd

def load_transcriptions_to_dataframe(folder_path):
    data = []
    for subfolder in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, subfolder)
        if os.path.isdir(subfolder_path):
            for filename in os.listdir(subfolder_path):
                if filename.lower().endswith('.txt'):
                    file_path = os.path.join(subfolder_path, filename)
                    with open(file_path, 'r', encoding='utf-8') as file:
                        transcription = file.read()
                    data.append({'file_name': filename, 'transcription': transcription})
    df = pd.DataFrame(data)
    return df

df_transcriptions = load_transcriptions_to_dataframe(folder_path)

#%% mark 

def identify_and_mark_transcriptions(folder_path, start_phrases):
    marked_files = []
    for subfolder in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, subfolder)
        if os.path.isdir(subfolder_path):
            for filename in os.listdir(subfolder_path):
                if filename.lower().endswith('.txt'):
                    file_path = os.path.join(subfolder_path, filename)
                    with open(file_path, 'r', encoding='utf-8') as file:
                        first_line = file.readline().strip().lower()
                    # Check if the first line starts with any of the specified phrases
                    if any(first_line.startswith(phrase.lower()) for phrase in start_phrases):
                        marked_files.append(file_path[:-4])  # Append path without '.txt'
    
    # Save the list of marked files to a text file
    if marked_files:
        with open('marked_files_index.txt', 'w', encoding='utf-8') as index_file:
            for file_path in marked_files:
                index_file.write(file_path + '\n')

# Example usage:
start_phrases = ["thanks for watching", "thank you for watching"]
identify_and_mark_transcriptions(folder_path, start_phrases)












