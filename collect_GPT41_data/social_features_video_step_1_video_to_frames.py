"""
This is the first step in the process of collecting video data.
At this step, image frames are captured from the videos in the dataset and the audio is saved as an .mp3 file.

Lauri Suominen 05.06.2025
"""

import subprocess
import os

#%% Change parameters

video_folder = 'path/stimulus' # CHANGE
output_folder = 'path/stimulus_frames' #CHANGE

#%% Script

# Retrieves the video duration in seconds using the ffprobe tool
def get_video_duration(video_path):
    # Use ffprobe to get the video duration
    command = ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', video_path]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    duration = float(result.stdout)
    return duration

# Takes a single frame from a specific point in the video and saves it
def extract_frame_at_second(video_path, output_folder, second, video_filename):
    video_basename = os.path.splitext(video_filename)[0]
    # Each video frame is saved in a separate folder named after the video
    video_output_folder = os.path.join(output_folder, video_basename)
    if not os.path.exists(video_output_folder):
        os.makedirs(video_output_folder)
    # Filename of the frame to be saved
    output_file = os.path.join(video_output_folder, f"frame_{second:.1f}s.png")
    # ffmpeg command to record a frame from a specific point
    command = ['ffmpeg', '-ss', str(second), '-i', video_path, '-frames:v', '1', output_file, '-y']
    subprocess.run(command, capture_output=True)
    
# Extracts audio from video and saves it in mp3 format
def extract_audio(video_path, output_folder, video_filename):
    video_basename = os.path.splitext(video_filename)[0]
    video_output_folder = os.path.join(output_folder, video_basename)
    if not os.path.exists(video_output_folder):
        os.makedirs(video_output_folder)
    # Filename of the audio to be recorded
    audio_output_file = os.path.join(video_output_folder, f"{video_basename}.mp3")
    # ffmpeg command to extract audio from video
    command = ['ffmpeg', '-i', video_path, '-vn', '-acodec', 'libmp3lame', audio_output_file]
    subprocess.run(command, capture_output=True)

# Create a output folder if it does not already exist
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# Looping through all mp4 videos in a given folder
for file in os.listdir(video_folder):
    if file.endswith(".mp4"):
        video_path = os.path.join(video_folder, file)
        # Get video duration
        duration = get_video_duration(video_path)
        # Extract audio
        extract_audio(video_path, output_folder, file)
        # Take screenshots at specific points in the video duration (1/9 interval)
        extract_frame_at_second(video_path, output_folder, duration * (1/9), file)  # 1/9
        extract_frame_at_second(video_path, output_folder, duration * (2/9), file)  # 2/9
        extract_frame_at_second(video_path, output_folder, duration * (3/9), file)  # 3/9
        extract_frame_at_second(video_path, output_folder, duration * (4/9), file)  # 4/9
        extract_frame_at_second(video_path, output_folder, duration * (5/9), file)  # 5/9
        extract_frame_at_second(video_path, output_folder, duration * (6/9), file)  # 6/9
        extract_frame_at_second(video_path, output_folder, duration * (7/9), file)  # 7/9
        extract_frame_at_second(video_path, output_folder, duration * (8/9), file)  # 8/9
        