import os
from openai import OpenAI
import argparse


PROMPT_STRING = """Convert a given yml schema definition to a SQL CREATE TABLE statement.
STRING, FLOAT, DOUBLE are valid SQL datatypes - use as is. Convert TIMESTAMP to TIMESTAMP_LTZ(3).
_uuid and event_time columns are special and annotated with METADATA as shown below.
Here is an example of a yml schema definition and the SQL file to convert to:
==YML==
---
name: "promoteToMain"
schema_version: "1"
partial_schema: false
columns:
- name: "_uuid"
  type: "STRING"
  tests:
    - "not_null"
- name: "deploymentId"
  type: "STRING"
  tests:
  - "not_null"
- name: "projectId"
  type: "STRING"
  tests:
  - "not_null"
- name: "userId"
  type: "STRING"
  tests:
    - "not_null"
- name: "event_time"
  type: "TIMESTAMP"
  tests:
  - "not_null"
==SQL==
CREATE TABLE PromoteToMain (
    _uuid STRING NOT NULL METADATA FROM 'uuid',
    deploymentId STRING NOT NULL,
    projectId STRING NOT NULL,
    userId STRING NOT NULL,
    event_time TIMESTAMP_LTZ(3) NOT NULL METADATA FROM 'timestamp'
);
==
Apply this transformation to the following config file and produce a text output without markdown syntax or escaping that only contains the result:
"""

def process_files(directory, openai_key):
    client = OpenAI(
        api_key=openai_key,
    )
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.schema.yml'):
                file_path = os.path.join(root, file)

                # Read the contents of the file
                with open(file_path, 'r') as f:
                    content = f.read()

                print("Converting: " + file_path)

                # Append PROMPT_STRING to the content
                appended_content = content + PROMPT_STRING

                # Send the appended content to OpenAI
                response = client.chat.completions.create(
                    model="gpt-4o",
                    messages=[
                        {
                            "role": "user",
                            "content": appended_content,
                        },
                    ],
                    max_tokens=2048
                )
                new_content = response.choices[0].message.content

                # Replace the original file content
                new_file_path = file_path + '.sql'
                with open(new_file_path, 'w') as f:
                    f.write(new_content)

def parse_arguments():
    parser = argparse.ArgumentParser(description='Converting YAML to SQL files with OpenAI.')
    parser.add_argument('directory', type=str, help='The directory to process')
    parser.add_argument('openai_key', type=str, help='The OpenAI API key')
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_arguments()
    process_files(args.directory, args.openai_key)