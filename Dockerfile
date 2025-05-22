FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    sudo wget vim openssh-server openssh-client openjdk-8-jdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up Java
RUN mv /usr/lib/jvm/java-1.8.0-openjdk-amd64 /usr/lib/jvm/java

# Create Hadoop user and group
RUN groupadd hadoop && \
    useradd -m -g hadoop hduser && \
    echo "hduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# === Install Hadoop ===
ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp
RUN tar -xzvf /tmp/hadoop-3.3.6.tar.gz -C /usr/local && \
    mv /usr/local/hadoop-3.3.6 /usr/local/hadoop && \
    mkdir -p /usr/local/hadoop/namenode /usr/local/hadoop/datanode && \
    chown -R hduser:hadoop /usr/local/hadoop && \
    chmod -R 777 /usr/local/hadoop

# === Install Zookeeper ===
ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp
RUN tar -xzvf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-zookeeper-3.8.4-bin /usr/local/zookeeper && \
    cp /usr/local/zookeeper/conf/zoo_sample.cfg /usr/local/zookeeper/conf/zoo.cfg && \
    mkdir -p /usr/local/zookeeper/data && \
    chown -R hduser:hadoop /usr/local/zookeeper && \
    chmod -R 777 /usr/local/zookeeper

# === Install HBase ===
ADD https://dlcdn.apache.org/hbase/2.4.18/hbase-2.4.18-bin.tar.gz /tmp
RUN tar -xzvf /tmp/hbase-2.4.18-bin.tar.gz -C /usr/local && \
    mv /usr/local/hbase-2.4.18 /usr/local/hbase && \
    chown -R hduser:hadoop /usr/local/hbase && \
    chmod -R 777 /usr/local/hbase

# Switch to Hadoop user
USER hduser
WORKDIR /home/hduser

# Set up SSH for Hadoop
RUN ssh-keygen -t rsa -N "" -f /home/hduser/.ssh/id_rsa && \
    cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys && \
    chmod 600 /home/hduser/.ssh/authorized_keys

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java
ENV HADOOP_HOME=/usr/local/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_MAPRED_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_HDFS_HOME=$HADOOP_HOME
ENV YARN_HOME=$HADOOP_HOME
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH
ENV HBASE_HOME=/usr/local/hbase
ENV PATH=$HBASE_HOME/bin:$PATH

# Copy Hadoop configuration files
COPY hadoop-env.sh $HADOOP_CONF_DIR/hadoop-env.sh
COPY core-site.xml $HADOOP_CONF_DIR/core-site.xml
COPY hdfs-site.xml $HADOOP_CONF_DIR/hdfs-site.xml
COPY mapred-site.xml $HADOOP_CONF_DIR/mapred-site.xml
COPY yarn-site.xml $HADOOP_CONF_DIR/yarn-site.xml
COPY workers $HADOOP_CONF_DIR/workers

# Copy Zookeeper configuration
COPY zoo.cfg $ZOOKEEPER_HOME/conf/zoo.cfg

# Copy HBase configuration
COPY hbase-site.xml $HBASE_HOME/conf/hbase-site.xml
COPY regionservers $HBASE_HOME/conf/regionservers


COPY hbase-env.sh $HBASE_HOME/conf/hbase-env.sh

# Create necessary directories
RUN mkdir -p /usr/local/hadoop/journal/data /usr/local/hadoop/zookeeper/data && \
    chown -R hduser:hadoop /usr/local/hadoop/journal /usr/local/hadoop/zookeeper && \
    chmod -R 777 /usr/local/hadoop/journal /usr/local/hadoop/zookeeper

# Copy entrypoint script
COPY ./entrypoint.sh /home/hduser/entrypoint.sh
RUN sudo chmod +x /home/hduser/entrypoint.sh

VOLUME [ "/usr/local/hadoop/journal/data" ]
VOLUME [ "/usr/local/hadoop/namenode" ]
VOLUME [ "/usr/local/hadoop/datanode" ]

# Set the entrypoint
ENTRYPOINT ["/home/hduser/entrypoint.sh"]
