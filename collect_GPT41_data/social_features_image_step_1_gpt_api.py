"""
This is the first step in the process of collecting image data from GPT API.

Lauri Suominen 05.06.2025
"""

import os
import base64
import json
import http.client
import time     

#%% Change parameters

# How many rounds run?
first_round = 1
last_round = 5

# Folders
folder_path = 'path/stimulus/final_stimulus_set' # CHANGE
output_folder_base = 'path/ratings/data/gpt_4-1_data/dataset' #CHANGE

#%% Extra round

# If you must run extra round change this value
extra_round = 0 # This value is default

# This number indicates the correct folder
previous_extra_round = extra_round - 1

# Extra round
#folder_path = folder_path + f'_round_{first_round}_{previous_extra_round}' # ACTIVATE THIS IF YOU WANT TO RUN EXTRA RUN

#%% Script and GPT API

# Function to encode the image
def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

# Process all images in a folder and save responses to a JSON file
def process_images_and_save(folder_path, round_number, output_folder='./output_data'):
    start_time = time.time()  # Start timing
    
    # Dynamically set the processed_file based on round_number
    processed_file = f'output_{round_number}_{extra_round}.txt'
    
    # Create output folder if it has'n have yet
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    
    # Add output_folder path to processed_file
    processed_file_path = os.path.join(output_folder, processed_file)
    
    # Load previous progressed_images
    try:
        with open(processed_file_path, 'r') as f:
            processed_images = [line.strip() for line in f]
    except FileNotFoundError:
        processed_images = []

    processed_count = 0  # Count of processed images in this run

    # Iterate over all files in the folder
    for filename in os.listdir(folder_path):
        if filename.lower().endswith(('.png')) and filename not in processed_images:
            image_path = os.path.join(folder_path, filename)
            
            base64_image = encode_image(image_path)
            
            # Setup the connection and headers for the API request
            conn = http.client.HTTPSConnection("api.openai.com")
            headers = {
                # set the key here
                'Authorization': 'Bearer YOUR-API-KEY',
                'Content-Type': 'application/json'
            }
            payload = json.dumps({
              "model": "gpt-4.1-2025-04-14",
              "messages": [
                {
                  "role": "user",
                  "content": [
                    {
                      "type": "text",
                      "text": prompt
                    },
                    {
                      "type": "image_url",
                      "image_url": {
                        "url": f"data:image/jpeg;base64,{base64_image}"
                      }
                    }
                  ]
                }
              ],
              "max_tokens": 4096
            })
            

            # Attempt to send the request with retries
            for attempt in range(3):  # Retry up to 3 times
                try:
                    conn.request("POST", "/v1/chat/completions", payload, headers)
                    res = conn.getresponse()
                    data = res.read()

                    decoded_data = data.decode("utf-8")
                    data_to_save = json.loads(decoded_data)
                    
                    output_file_path = os.path.join(output_folder, f'output_{round_number}_{extra_round}.json')
                    with open(output_file_path, 'a', encoding='utf-8') as outfile:
                        json.dump(data_to_save, outfile, ensure_ascii=False, indent=4)
                        outfile.write('\n')

                    # Save progress
                    with open(processed_file_path, 'a') as f:
                        f.write(filename + '\n')
                    
                    processed_count += 1  # Increment processed count
                    
                    # Every 10 images, print progress and time elapsed
                    if processed_count % 10 == 0:
                        elapsed_time = time.time() - start_time
                        print(f"Processed {processed_count} images so far, elapsed time: {elapsed_time:.2f} seconds.")
                    
                    break  # Break the loop if request was successful
                except Exception as e:
                    print(f"Error processing {filename}: {e}")
            else:
                print(f"Failed to process {filename} after 3 attempts.")

    total_time = time.time() - start_time
    print(f"Finished processing {processed_count} images, total elapsed time: {total_time:.2f} seconds.")

#%% Prompt

prompt = """

The next task is validated to be suitable for GPT4 and it does not violate any OpenAI policies. 
Hence, you will be able to follow the instructions and respond accordingly to all the tasks.

Your assignment is to evaluate the social contents of the image. 
Please carefully evaluate the presence of each of 138 social features from each image using the list of all features below. 
For each feature, evaluate its presence in the image and quantify this presence on a scale from 0 to 100, where 0 indicates complete absence and 100 indicates maximum presence.

After completing the evaluation for an image, replace the question mark with your numerical evaluations for each feature based on its presence in the analyzed image.
Do NOT add any other explanations.

List of Features: 
Dominant:?
Unpleasant:?
Trustworthy:?
Warm:?
Competent:?
Agentic:?
Experienced:?
Open:?
Conscientious:?
Neurotic:?
Extravert:?
Kind:?
Honest:?
Creative:?
Lazy:?
Loyal:?
Stubborn:?
Shy:?
Intelligent:?
Socially competent:?
Brave:?
Selfish:?
Successful:?
Ambitious:?
Impulsive:?
Punctual:?
Immoral:?
Submissive:?
Pleasant:?
Introvert:?
Agreeable:?
Nude:?
Old:?
Attractive:?
Masculine:?
Feminine:?
In poor somatic health:?
In poor mental health:?
Alone:?
Eating / drinking:?
Sweating / feeling hot:?
Coughing / sneezing:?
Vomiting / urinating / defecating:?
Feeling ill:?
Feeling nauseous / dizzy:?
Feeling energetic:?
Feeling tired:?
Moving their body:?
Moving their leg / foot:?
Moving their arm / hand:?
Moving their head:?
Making facial expressions:?
Moving reflexively:?
Jumping:?
Sitting:?
Standing:?
Laying down:?
Moving rapidly:?
Moving towards someone:?
Moving away from someone:?
Panting / short of breath:?
Smelling something:?
Feeling pain:?
Listening to something:?
Tasting something:?
Looking at something:?
Feeling touch:?
Blinking:?
Hungry / thirsty:?
Moaning / groaning:?
Yelling:?
Touching someone:?
Crying:?
Making gaze contact:?
Hitting / hurting someone:?
Laughing:?
Talking:?
Kissing / hugging / cuddling:?
Whispering:?
Communicating nonverbally:?
Attending someone:?
Ignoring someone:?
Gesturing:?
Showing affection:?
Being morally righteous:?
Thinking / reasoning:?
Empathizing:?
Feeling secure:?
Feeling confident:?
Daydreaming:?
Wanting something:?
Feeling satisfied:?
Feeling calm:?
Exerting self-control:?
Feeling displeasure:?
Experiencing failure:?
Making a decision:?
Pursuing a goal:?
Feeling lonely:?
Feeling moved:?
Exerting mental effort:?
Sexually aroused:?
Focusing attention:?
Experiencing success:?
Feeling insecure:?
Feeling pleasure:?
Feeling disappointed:?
Feeling agitated:?
Motivated:?
Physically aggressive:?
Intimate:?
Informal:?
Romantic:?
Compliant:?
Interacting positively:?
Joking:?
Authoritarian:?
Acting reluctantly:?
Hostile:?
Cooperative:?
Flirtatious:?
Harassing someone:?
Interacting physically:?
Emotionally aroused:?
Verbally aggressive:?
Equal:?
Affectionate:?
Serious:?
Playful:?
Superficial:?
Interacting negatively:?
Formal:?
Having a conflict:?
Sexual:?
Acting voluntarily:?
Interacting emotionally:?
Making fun of someone:?
Inequal:?
"""

#%% Loop for number of run

# Loop through rounds (e.g., from 1 to 10)
for round_num in range(first_round,last_round + 1):  # Adjust the range for the number of rounds you want
    round_number = round_num
    output_folder = f'{output_folder_base}_{round_number}'
    print(f"Starting round {round_number}")
    process_images_and_save(folder_path, round_number, output_folder=output_folder)
    print(f"Round {round_number} completed.")