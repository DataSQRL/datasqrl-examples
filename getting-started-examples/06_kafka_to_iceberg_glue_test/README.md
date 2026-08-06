# Kafka to Iceberg in S3 with AWS Glue Using DataSQRL

This project demonstrates how to use [DataSQRL](https://datasqrl.com) to build a streaming pipeline that:

- Reads data from a Kafka topic
- Writes data to S3 in Iceberg table format via AWS Glue

## ☁️ AWS Prerequisites

1. Create an AWS S3 bucket (e.g. `my-iceberg-table-test`) that you will use for the test ([docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html))
   1. Note the region where you created the bucket
2. Create an AWS token for your user, that can be used for Flink/Iceberg to auth
   1. Sign in to AWS Console → Go to IAM service
   2. Navigate to *Users* → Find your username → Click on it
   3. Security credentials tab → Scroll to *Access keys*
   4. Click *Create access key*
   5. Choose use case (*Application running outside AWS*) → Next
   6. Copy both values or download: `AWS_ACCESS_KEY_ID` (starts with AKIA...) `AWS_SECRET_ACCESS_KEY` (long random string)
3. Make sure that your user has S3 and Glue access
4. Create a Glue database
   1. Go to AWS Glue Service
   2. Left sidebar → Click on "Data Catalog Tables" → Click “Databases”
   3. Click *Add database*
   4. Name it `mydatabase` (has to match with what is in the `package.json` config)

## 🐳 Running DataSQRL

Run the following command from the project root where your `package.json` and SQRL scripts reside:
```bash
docker run -it --rm \
  -p 8888:8888 \
  -p 8081:8081 \
  -p 9092:9092 \
  -v $PWD:/workspace \
  -e AWS_ACCESS_KEY_ID="<my-access-key>" \
  -e AWS_SECRET_ACCESS_KEY="<my-secret-key" \
  -e AWS_REGION="<my-region>" \
  datasqrl/cmd:latest run -c package.json
```

## Generate Data

* Go to `data-generator` folder
  * `python3 load_data.py <jsonl_file> <topic_name>`
* To send Contact data
```bash
python3 load_data.py contacts.jsonl contacts
```

## Output

* Records should show up in the S3 bucket under `s3://my-iceberg-table-test/mydatabase.db/mycontacts`,
  and they are queryable via Amazon Athena.
