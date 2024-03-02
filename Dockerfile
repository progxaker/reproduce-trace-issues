# Download Spark
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 AS spark-builder

USER 0

WORKDIR /tmp
RUN microdnf -y install gzip
RUN curl -fsSLo /tmp/spark.tgz https://archive.apache.org/dist/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz && tar -xzf spark.tgz

# Build Application Insights JVM agent
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 AS appinsights-builder

USER 0

RUN microdnf -y install git

WORKDIR /tmp
RUN git clone https://github.com/microsoft/ApplicationInsights-Java/

WORKDIR /tmp/ApplicationInsights-Java/
RUN git checkout 3.4.19
#RUN git checkout 3.5.0
RUN git config --global user.email "test@example.com" && git config --global user.name "Test"

## Cache original build
RUN ./gradlew assemble

COPY metrics.patch /tmp/metrics.patch
RUN git am -3 /tmp/metrics.patch && ./gradlew assemble

# Build the application
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 AS app-builder

WORKDIR /tmp/project/

COPY SimpleApp.java ./src/main/java/SimpleApp.java
COPY pom.xml ./pom.xml

RUN mvn package

# Run Spark
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 

USER 0

WORKDIR /tmp/

RUN microdnf -y install procps
COPY --from=spark-builder /tmp/spark-3.5.0-bin-hadoop3/ /tmp/spark/
COPY --from=appinsights-builder /tmp/ApplicationInsights-Java/agent/agent/build/libs/applicationinsights-agent-3.4.19-SNAPSHOT.jar /tmp/applicationinsights-agent.jar
#COPY --from=appinsights-builder /tmp/ApplicationInsights-Java/agent/agent/build/libs/applicationinsights-agent-3.5.0-SNAPSHOT.jar /tmp/applicationinsights-agent.jar
COPY --from=app-builder /tmp/project/target/simple-project-1.0.jar /tmp/simple-project-1.0.jar


ENV APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL="TRACE"
ENV JAVA_TOOL_OPTIONS="-javaagent:/tmp/applicationinsights-agent.jar"
ENV CLASSPATH="/tmp/spark/jars/"
ENV APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=00000000-0000-0000-0000-0FEEDDADBEEF;IngestionEndpoint=http://host.testcontainers.internal:6060/;LiveEndpoint=http://host.testcontainers.internal:6060/"

CMD ["/tmp/spark/bin/spark-submit", "--class", "SimpleApp", "--master", "local[4]", "--conf", "spark.jars.ivy=/tmp/.ivy", "/tmp/simple-project-1.0.jar"]
