# Download Spark
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 AS spark-builder

USER 0

WORKDIR /tmp
RUN microdnf -y install gzip
RUN curl -fsSLo /tmp/spark.tgz https://archive.apache.org/dist/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz && tar -xzf spark.tgz

# Build Application Insights JVM agent
#
# Uncomment if you would like to apply a patch
#
#FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 AS appinsights-builder
#
#USER 0
#
#RUN microdnf -y install git
#
#WORKDIR /tmp
#RUN git clone https://github.com/microsoft/ApplicationInsights-Java/
#
#WORKDIR /tmp/ApplicationInsights-Java/
#RUN git checkout 3.4.19
#RUN git config --global user.email "test@example.com" && git config --global user.name "Test"
#
### Cache original build
#RUN ./gradlew --parallel --no-daemon --build-cache assemble
#
#COPY metrics.patch /tmp/metrics.patch
#RUN git am -3 /tmp/metrics.patch && ./gradlew --parallel --no-daemon assemble

# Build the application
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 AS app-builder

WORKDIR /tmp/project/

COPY src/main/java/SimpleApp.java ./src/main/java/SimpleApp.java
COPY pom.xml ./pom.xml

RUN mvn package

# Run Spark
FROM registry.access.redhat.com/ubi8/openjdk-17:1.18-2.1705573234 

USER 0

WORKDIR /tmp/

RUN microdnf -y install procps
COPY --from=spark-builder /tmp/spark-3.5.0-bin-hadoop3/ /tmp/spark/

#
# Uncomment if you would like to apply a patch
#
#COPY --from=appinsights-builder /tmp/ApplicationInsights-Java/agent/agent/build/libs/applicationinsights-agent-3.4.19-SNAPSHOT.jar /tmp/applicationinsights-agent.jar

RUN curl -fsSLo applicationinsights-agent.jar https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.5.1/applicationinsights-agent-3.5.1.jar
COPY --from=app-builder /tmp/project/target/simple-project-1.0.jar /tmp/simple-project-1.0.jar


ENV APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL="TRACE"
ENV JAVA_TOOL_OPTIONS=""
ENV CLASSPATH="/tmp/spark/jars/"
ENV APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=00000000-0000-0000-0000-0FEEDDADBEEF;IngestionEndpoint=http://host.testcontainers.internal:6060/;LiveEndpoint=http://host.testcontainers.internal:6060/"

CMD ["/tmp/spark/bin/spark-submit", "--class", "SimpleApp", "--master", "local[4]", "/tmp/simple-project-1.0.jar"]
