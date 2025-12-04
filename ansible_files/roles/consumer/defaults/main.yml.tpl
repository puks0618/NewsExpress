# Kafka Configuration
kafka_topic: "news-stream"
kafka_broker: "${kafka_server_private_ip}:9092"

# GCS Configuration
temp_bucket: "${temp_bucket_name}"

# BigQuery Configuration
bq_dataset_id: "${project_id}.news_stream"

# Privacy Configuration
epsilon: "${epsilon}"
