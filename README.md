# Reproduce the problem with trace logs

This repository is created to reproduce the issue described
[here](https://github.com/microsoft/ApplicationInsights-Java/issues/3524).

## Windows

### Install Spark

1. Download Spark:  
   https://archive.apache.org/dist/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
2. Download Hadoop compiled for Windows (`winutils.exe`):  
   https://github.com/cdarlint/winutils/raw/master/hadoop-3.3.5/bin/winutils.exe
3. Navigate to the folder where Spark and Hadoop will be placed,  
   for example: `C:\Users\progxaker\Downloads`.
4. Create a new folder named Spark  
   (e.g., `C:\Users\progxaker\Downloads\Spark`).
5. Unpack the Spark archive to the created folder  
   (e.g., `C:\Users\progxaker\Downloads\Spark\spark-3.5.0-bin-hadoop3`).
6. Create a new folder named Hadoop  
   (e.g., `C:\Users\progxaker\Downloads\Hadoop`).
7. Create a new folder named bin in the created folder  
   (e.g., `C:\Users\progxaker\Downloads\Hadoop\bin`).
8. Move the Hadoop binary to the created folder  
   (e.g., `C:\Users\progxaker\Downloads\Hadoop\bin\winutils.exe`).

### Download the Application Insights JVM agent

1. Open https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.5.1/applicationinsights-agent-3.5.1.jar .

### Build an application

1. Open "Command Prompt".
2. Navigate to the folder with the cloned repository.
3. Build the application: `mvn package`.

### Run the application

#### Successful run

1. Go to the folder with the Application Insights JVM agent.
2. Open "Command Prompt".
3. Run the following:
    ```cmd
    SET SPARK_HOME=<the-folder-from-step-5>
    SET HADOOP_HOME=<the-folder-from-step-6>
    %SPARK_HOME%\bin\spark-submit --class SimpleApp --master local[4] <absolute-path-to-the-clonned-repository>\target\simple-project-1.0.jar
    ```
    Please note that **no quotes** are required.
4. Run with the Application Insights JVM agent:
    ```cmd
    SET SPARK_HOME=<folder-from-step-5>
    SET HADOOP_HOME=<folder-from-step-6>
    SET APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>
    SET APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL=TRACE
    %SPARK_HOME%\bin\spark-submit --conf "spark.driver.extraJavaOptions='-javaagent:applicationinsights-agent-3.5.1.jar'" --class SimpleApp --master local[4] <absolute-path-to-the-clonned-repository>\target\simple-project-1.0.jar
    ```

#### Failed run

1. Go to the folder with the Application Insights JVM agent.
2. Open "Command Prompt".
3. Run the following:
    ```cmd
    SET SPARK_HOME=<the-folder-from-step-5>
    SET HADOOP_HOME=<the-folder-from-step-6>
    SET JAVA_TOOL_OPTIONS=-javaagent:application-insights-3.5.1.jar
    SET APPLICATIONINSIGHTS_CONNECTION_STRING=<connection-string>
    SET APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL=TRACE
    %SPARK_HOME%\bin\spark-submit --class SimpleApp --master local[4] <absolute-path-to-the-clonned-repository>\target\simple-project-1.0.jar
    ```
    Please note that **no quotes** are required.

## (Linux) Docker

### Build a Docker image

```bash
docker build -t reproduce-trace-issues:v1 .
```

### Run the image

#### Successful run

```bash
docker run --rm -ti --env APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>" \
                    --env APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL="TRACE" \
                    reproduce-trace-issues:v1 \
                    /tmp/spark/bin/spark-submit --conf "spark.driver.extraJavaOptions='-javaagent:/tmp/applicationinsights-agent.jar'" \
                    --class SimpleApp --master local[4] /tmp/simple-project-1.0.jar
```

#### Failed run

```bash
docker run --rm -ti --env APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>" \
                    --env APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL="TRACE" \
                    --env JAVA_TOOL_OPTIONS="-javaagent:/tmp/applicationinsights-agent.jar" \
                    reproduce-trace-issues:v1
```
