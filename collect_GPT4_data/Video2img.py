# -*- coding: utf-8 -*-
"""

Batch process of extracting images and audio from video cilps

@author: 吴雨航 Yuhang Wu
@Email: wuyuhang@ruc.edu.cn 
First created: 20/3/2024 
Last modified: 15/5/2024

"""

import math
import subprocess
import os

#%% Extract vedio and audio at the same time 

def get_video_duration(video_path):
    # Use ffprobe to get the video duration
    command = ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', video_path]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    duration = float(result.stdout)
    return duration

def extract_frame_at_second(video_path, output_folder, second, video_filename):
    video_basename = os.path.splitext(video_filename)[0]
    # Each video frame is saved in a separate folder named after the video
    video_output_folder = os.path.join(output_folder, video_basename)
    if not os.path.exists(video_output_folder):
        os.makedirs(video_output_folder)
    output_file = os.path.join(video_output_folder, f"frame_{second:.1f}s.png")
    command = ['ffmpeg', '-ss', str(second), '-i', video_path, '-frames:v', '1', output_file, '-y']
    subprocess.run(command, capture_output=True)
    
def extract_audio(video_path, output_folder, video_filename):
    video_basename = os.path.splitext(video_filename)[0]
    video_output_folder = os.path.join(output_folder, video_basename)
    if not os.path.exists(video_output_folder):
        os.makedirs(video_output_folder)
    audio_output_file = os.path.join(video_output_folder, f"{video_basename}.mp3")
    command = ['ffmpeg', '-i', video_path, '-vn', '-acodec', 'libmp3lame', audio_output_file]
    subprocess.run(command, capture_output=True)

video_folder = 'YOUR_SOURCE_FOLDER' 
output_folder = 'YOUR_TARGET_FOLDER'  

if not os.path.exists(output_folder):
    os.makedirs(output_folder)

for file in os.listdir(video_folder):
    if file.endswith(".mp4"):
        video_path = os.path.join(video_folder, file)
        # Get video duration
        duration = get_video_duration(video_path)
        extract_audio(video_path, output_folder, file)  # Extract audio
        if duration <= 10:
            # If the video length is less than 10 seconds, extract the frames at 1/4 and 3/4
            extract_frame_at_second(video_path, output_folder, duration * 0.25, file)
            extract_frame_at_second(video_path, output_folder, duration * 0.75, file)
        else:
            extract_frame_at_second(video_path, output_folder, duration * 0.125, file)  
            extract_frame_at_second(video_path, output_folder, duration * 0.375, file)  
            extract_frame_at_second(video_path, output_folder, duration * 0.625, file)  
            extract_frame_at_second(video_path, output_folder, duration * 0.875, file)

