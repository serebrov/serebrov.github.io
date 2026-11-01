---
title: "Google Colab notebook - input and output, OpenAI TTS API"
date: 2023-11-09
tags: [google-colab, ai, tts]
type: note
url: "/html/2023-11-09-google-colab-input-and-output-openai-tts.html"
---

# Running OpenAI TTS API in Google Colab

The example below runs OpenAI TTS API in a Google Colab notebook.
The process involves some input and output:
- Prompt the user for API key
- Run the API method
- Save result into a file

I have a notebook with two cells.

## First: Setup cell

```python
# @title Notebook Setup
# @markdown Please, run this cell first. You'll be prompted for your OpenAI API Keys.
# @markdown https://platform.openai.com/api-keys
!pip install openai tiktoken > /dev/null 2>&1

from getpass import getpass
from openai import OpenAI

# Prompt for API key and create a client
api_key = getpass('OpenAI API Key: ')
client = OpenAI(api_key=api_key)
```

For input we use [getpass](https://docs.python.org/3/library/getpass.html).

<!-- more -->

## Second: Main cell

```python
# @markdown This cell can be run multiple times to generate audio samples. All results will be saved to your Google Drive in the OpenAI_TTS_Samples folder.

import io
import os
import time

from IPython.display import Audio, display
from google.colab import drive

# Mount Google Drive to /content/gdrive path.
drive.mount('/content/gdrive')

# Output folder is OpenAI_TTS_Samples, it will be created
# if it does not exist.
out_path = "/content/gdrive/MyDrive/OpenAI_TTS_Samples/"
try:
    os.mkdir(out_path)
except FileExistsError:
   pass

voices = ("alloy", "echo", "fable", "onyx", "nova", "shimmer")
input="""
Today is a wonderful day to learn Vim!
"""

# Loop through voices and generate a sample for each voice
for voice in voices:
  response = client.audio.speech.create(
    model="tts-1-hd",
    voice=voice,
    input=input
  )

  # Prepare file name - YYYY-MM-DD-HH-MM-SS_voice.mp3
  timestr = time.strftime("%Y-%m-%d-%H-%M-%S")
  speech_file_name = f"{timestr}_{voice}.mp3"
  speech_file_path = out_path + speech_file_name

  # Save generated audio to the file.
  response.stream_to_file(speech_file_path)

  # Display files in the notebook as <audio> element
  display(speech_file_name, Audio(speech_file_path, autoplay=False))
```

Here we use Google Colab's [`drive` library](https://colab.research.google.com/notebooks/io.ipynb#scrollTo=u22w3BFiOveA) to save files to Google Drive and the [display](https://ipython.readthedocs.io/en/stable/api/generated/IPython.display.html) function.

Resources:

* [Welcome To Colaboratory](https://colab.research.google.com/)
* [External data: Local Files, Drive, Sheets, and Cloud Storage](https://colab.research.google.com/notebooks/io.ipynb)
