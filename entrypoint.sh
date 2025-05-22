#!/bin/bash

# COMMON SETUP FOR ALL NODES
sudo service ssh start


# Check if hostname contains "master"
if [[ "$HOSTNAME" == *"master"* ]]; then
    # Assign myid based on hostname
    ID=$(echo $HOSTNAME | tail -c 2) 
    echo $ID > /usr/local/zookeeper/data/myid

    hdfs --daemon start journalnode
    zkServer.sh start

    # Check if this is the first-time setup
    #if [ ! -f /usr/local/hadoop/namenode/formatted ]; then
        if [ "$ID" == "1" ]; then
            if [ ! -d /usr/local/hadoop/namenode/current ]; then
                sudo chmod -R 777 /usr/local/hadoop/namenode
                sudo chmod -R 777 /usr/local/hadoop/journal
                sudo chown -R hduser:hadoop /usr/local/hadoop/namenode
                sudo chown -R hduser:hadoop /usr/local/hadoop/journal
                hdfs namenode -format -force
                hdfs zkfc -formatZK -force
            else
                echo "NameNode already formatted. Skipping format step."
            fi
            hdfs --daemon start zkfc
            hdfs --daemon start namenode
  
        else 
            if [ ! -d /usr/local/hadoop/namenode/current ]; then
                echo "Bootstrapping standby NameNode for $HOSTNAME..."
                until hdfs haadmin -checkHealth nn1 ; do
                    sleep 5
                done
                hdfs namenode -bootstrapStandby
            else
                echo "NameNode already formatted. Skipping format step."
            fi
            hdfs --daemon start zkfc
            hdfs --daemon start namenode 
        fi
    yarn --daemon start resourcemanager
fi

# Worker node (Hadoop & HBase RegionServer)
if [[ "$HOSTNAME" == *"worker"* || "$HOSTNAME" == *"regionserver"* ]]; then
    echo "Starting DataNode and RegionServer on $HOSTNAME..."
    sudo chmod -R 777 /usr/local/hadoop/datanode
    sudo chown -R hduser:hadoop /usr/local/hadoop/datanode
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
    hbase-daemon.sh start regionserver
fi

# HBase Master startup
if [[ "$HOSTNAME" == *"hbase"* ]]; then
  echo "Starting HBase Master on $HOSTNAME..."
  hbase-daemon.sh start master
fi


sleep infinity