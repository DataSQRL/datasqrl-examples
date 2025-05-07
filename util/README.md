# Python Utilities

Some python utilities for loading and reading data from Kafka, upgrading DataSQRL jobs and more.

## Using Virtual Python Environment

It is recommended to use virtualenv to manage your python environment. Some IDEs require to place requirements.txt
and venv folder in the project root. That's why it is in the root, even though not all "modules" are utilizing it.

Here's how to use venv in this project:

- Create a virtual env in the project root folder: `python3 -m venv myenv`
- Activate the environment: `source myenv/bin/activate`
    - *you can later deactivate it with this command:* `deactivate`
- Install dependencies: `pip install -r requirements.txt`