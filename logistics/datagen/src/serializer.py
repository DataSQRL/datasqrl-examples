import json
from datetime import datetime


# Custom serializer function for datetime objects
def custom_serializer(obj):
    if isinstance(obj, datetime):
        return obj.isoformat()  # Serialize datetime objects to ISO 8601 format
    raise TypeError("Type not serializable")


def jsonify(obj):
    return json.dumps(obj, default=custom_serializer)
