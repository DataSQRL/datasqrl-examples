import gzip
import json

with gzip.open('click_part0001.json.gz', 'rt') as f:
    for line in f:
        data = json.loads(line)
        if '_source_time' in data:
            del data['_source_time']
        print(json.dumps(data))