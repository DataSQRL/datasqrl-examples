# Data Package for the Healthcare Study Monitoring Example

This data package is used by the Healthcare Study Monitoring Example which demonstrates DataSQRL's capabilities in
creating a data pipeline to monitor and analyze healthcare study data. We will create a pipeline that ingests raw data
from clinical studies and exposes the data through a GraphQL API. The pipeline will combine study metadata, patient
information, and sensor readings to provide insights into the studies.

## Data Overview

The Healthcare Study Monitoring pipeline aggregates data from multiple healthcare-related sources to track patient
information, clinical studies, and sensor data for health metrics. This pipeline integrates various datasets,
such as patient profiles, clinical sensor placements, and metadata about the clinical indicators being monitored.

### Datasets:
- Metadata: Information about the clinical indicators or markers being monitored, including acceptable ranges.
- Observation Groups: Details about groups of patients being studied as part of a clinical trial.
- Patients: Patient profile data, including demographic and health information.
- Sensor Placements: Information on the placement of sensors that monitor clinical indicators in real-time.

#### Metadata

This dataset contains information about the clinical indicators (also known as markers) being monitored. Each entry represents a health condition or symptom, along with a range of healthy values.

Fields:
- metadataId: Unique identifier for each clinical indicator.
- name: The name of the clinical indicator (e.g., "Vomiting coffee ground material Marker").
- lowRange: The lowest value that is considered within the normal range for the indicator.
- highRange: The highest value that is considered within the normal range for the indicator.
- lastUpdated: Timestamp when the metadata was last updated.

Sample Data:
```json
{"metadataId":6,"name":"Vomiting coffee ground material Marker","lowRange":9.0,"highRange":107.0,"lastUpdated":"2024-09-15T00:00:00Z"}
{"metadataId":7,"name":"Blood in urine (Hematuria) Marker","lowRange":31.0,"highRange":95.0,"lastUpdated":"2024-09-15T00:00:00Z"}
{"metadataId":8,"name":"Headache Marker","lowRange":10.0,"highRange":62.0,"lastUpdated":"2024-09-15T00:00:00Z"}
```

#### Observation Groups

This dataset tracks information about groups of patients who are part of a specific clinical study. Each group consists of multiple patients from a particular hospital or clinic.

Fields:
- groupId: Unique identifier for the observation group.
- studyId: Identifier for the healthcare study that the group is associated with.
- groupName: Name of the group, usually the name of the hospital or healthcare center.
- createdDate: The date when the observation group was created.
- patients: A list of patient IDs that belong to this group.

Sample Data:
```json
{"groupId":3,"studyId":1,"groupName":"BETSY JOHNSON HOSPITAL","createdDate":"2024-09-15T00:00:00Z","patients":[{"patientId":2},{"patientId":18},{"patientId":10},{"patientId":12}]}
{"groupId":4,"studyId":1,"groupName":"BHC ALHAMBRA HOSPITAL","createdDate":"2024-09-15T00:00:00Z","patients":[{"patientId":8},{"patientId":13}]}
```

#### Patients

This dataset contains the profile data for patients involved in clinical studies. It includes demographic details and key health information for each patient.

Fields:
- patientId: Unique identifier for each patient.
- studyId: Identifier for the healthcare study that the patient is enrolled in.
- name: Full name of the patient.
- bloodGroup: The patient's blood group (e.g., O+, B-).
- dateOfBirth: The patient's date of birth.
- diagnosis: The primary diagnosis or condition being treated or monitored for the patient.
- lastUpdated: Timestamp when the patient's information was last updated.

Sample Data:
```json
{"patientId":12,"studyId":1,"name":"Alaine Dietrich Sr.","bloodGroup":"O+","dateOfBirth":"2004-05-23","diagnosis":"Hypertension","lastUpdated":"2024-09-15T00:00:00Z"}
{"patientId":13,"studyId":1,"name":"Dale Harber V","bloodGroup":"B-","dateOfBirth":"1999-04-17","diagnosis":"Hypothyroidism","lastUpdated":"2024-09-15T00:00:00Z"}
{"patientId":14,"studyId":1,"name":"Jenelle Dicki","bloodGroup":"B-","dateOfBirth":"1962-07-26","diagnosis":"Heat Stroke","lastUpdated":"2024-09-15T00:00:00Z"}
```

#### Sensor Placements

This dataset tracks the placement of clinical sensors on patients, which are used to monitor specific clinical indicators. Each sensor is linked to a patient and a clinical marker (from the Metadata dataset).

Fields:
- sensorId: Unique identifier for the sensor.
- patientId: Identifier for the patient to whom the sensor is attached.
- metadataId: Identifier for the clinical indicator (or marker) being measured by the sensor.
- eventId: Unique event identifier associated with the sensor placement.
- placedTimestamp: The timestamp when the sensor was placed on the patient.

Sample Data:
```json
{"sensorId":15,"patientId":7,"metadataId":13,"eventId":"980ef0d6-a2d1-45c0-8e95-d70a17922464","placedTimestamp":"2024-09-15T00:00:00Z"}
{"sensorId":16,"patientId":24,"metadataId":7,"eventId":"782f445d-a610-4cd4-b891-f94341516bf7","placedTimestamp":"2024-09-15T00:00:00Z"}
{"sensorId":17,"patientId":23,"metadataId":10,"eventId":"35e05544-5a6f-43d7-8e6f-31a50f5851b6","placedTimestamp":"2024-09-15T00:00:00Z"}
```

## How to use the data package with an example

For a detailed explanation of how to work with this package, please refer to our comprehensive
[Healthcare Study Monitoring](https://github.com/DataSQRL/datasqrl-examples/tree/main/healthcare-study-monitoring/README.md) tutorial.

To apply it in your project, update the imports in the following files:

**creditcard-rewards.sqrl:**
```sql
IMPORT metrics-local.ClinicalIndicator;
IMPORT datasqrl.examples.medicalstudy.*;
```

**study-stream.sqrl:**
```sql
IMPORT metrics.ClinicalIndicator;
IMPORT datasqrl.examples.medicalstudy.SensorPlacements;
IMPORT datasqrl.examples.medicalstudy.Metadata;
```
