# 🌐 HBase Webpage Analytics – HA Cluster Project

This project implements a high-availability HBase + Hadoop cluster on Docker to manage and analyze large-scale web content data. It includes a versioned and TTL-enabled table for web pages, and provides operations and queries for content management, SEO, and performance analysis.

---

## 📦 Features

- High-Availability Hadoop + HBase cluster with ZooKeeper quorum
- Docker-based deployment with 9 service containers
- Shell and Python-based interaction with HBase using `HappyBase`
- TTL and versioned schema for real-time and historical web analytics
- Full support for pagination, filtering, version tracking, and SEO queries

---

## 🏗 Cluster Architecture

| Node        | Role(s)                                                             |
|-------------|----------------------------------------------------------------------|
| `hmaster1-3`| NameNode + JournalNode + ZooKeeper + HBase Master (HA)              |
| `hbase1/2`  | HBase Master (active/standby)                                       |
| `hworker`   | RegionServer + DataNode + NodeManager                               |
| `regionserver1/2` | RegionServer + DataNode + NodeManager                         |

All nodes are connected via `mynetwork`, and persistent volumes are configured for HDFS and ZooKeeper.

---

## 🗃️ HBase Table Schema

```hbase
create 'webpages',
  { NAME => 'content', VERSIONS => 3, TTL => 7776000 },     # 90 days
  { NAME => 'metadata', VERSIONS => 1 },
  { NAME => 'outlinks', VERSIONS => 2, TTL => 15552000 },   # 180 days
  { NAME => 'inlinks', VERSIONS => 2, TTL => 15552000 }
````
To run this cluster you need to create the image from dockerfile first 
docker build -t hbase:latest . 

----

## ⚙️ Setup Instructions

### 1. Build the Docker image
```bash
docker build -t hbase:latest .
```
###2. Start the Docker cluster
```bash
docker-compose up --build
````
###3. Enter hbase1 container and install Python
```bash
docker exec -it hbase1 bash
cd /script
./setup_python.sh     # Installs Python, pip, HappyBase, Faker,and Thrift
```
###4. Start Thrift service
```bash
hbase thrift start &
```
###5. Insert sample data
```bash
cd /script
python3 seo_loader.py
```

--

📂 Scripts
- setup_python.sh – Installs Python and required libraries inside the container
- seo_loader.py – Generates and inserts 20 random web pages with fake HTML, titles, timestamps, and link structure using Faker + HappyBase
