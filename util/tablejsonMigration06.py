import os
from openai import OpenAI
import argparse


PROMPT_STRING = """Given a json configuration file, produce a SQL CREATE table statement by:
- converting all fields nested under "flink" to connector options in the WITH clause
- converting the primary key
- converting the timestamp and watermark-millis to a watermark declaration.
- converting "metadata" entries to columns with the key as the column name: if the attribute is a 
  function call create a computed column, else create a metadata column with the data type and metadata attribute
Here is an example of a configuration file and the SQL file to convert to:
==JSON CONFIG==
{
  "version": 1,
  "flink" : {
    "format" : "flexible-json",
    "path" : "${DATA_PATH}/click.jsonl",
    "connector" : "filesystem"
  },
  "table" : {
    "type" : "source",
    "primary-key" : ["url","userid","timestamp"],
    "timestamp" : "timestamp",
    "watermark-millis" : "1"
  },
  "metadata" : {
    "timestamp": {
      "attribute": "time.EpochMilliToTimestamp(time)"
    },
    
  }
}
==SQL==
CREATE TABLE Click (
     `timestamp` AS EpochMilliToTimestamp(`time`),
     PRIMARY KEY (`url`, `userid`, `time`) NOT ENFORCED,
     WATERMARK FOR `timestamp` AS `timestamp` - INTERVAL '0.001' SECOND
) WITH (
      'format' = 'flexible-json',
      'path' = '${DATA_PATH}/click.jsonl',
      'source.monitor-interval' = '10 sec',
      'connector' = 'filesystem'
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
            if file.endswith('.table.sql'):
                file_path = os.path.join(root, file)

                # Read the contents of the file
                with open(file_path, 'r') as f:
                    content = f.read()

                # Skip the file if it contains 'CREATE TABLE'
                if 'CREATE TABLE' in content:
                    continue

                print("Converting: " + file_path)

                # Create a backup file
                backup_file_path = file_path + '.backup'
                with open(backup_file_path, 'w') as f:
                    f.write(content)

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
                with open(file_path, 'w') as f:
                    f.write(new_content)

def parse_arguments():
    parser = argparse.ArgumentParser(description='Process SQL files with OpenAI.')
    parser.add_argument('directory', type=str, help='The directory to process')
    parser.add_argument('openai_key', type=str, help='The OpenAI API key')
    return parser.parse_args()

if __name__ == '__main__':
    args = parse_arguments()
    process_files(args.directory, args.openai_key)