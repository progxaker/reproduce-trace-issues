# Reproduce the problem with trace logs

This repository is created to reproduce the issue described
[here](https://github.com/microsoft/ApplicationInsights-Java/issues/3524).

## Build a Docker image

```
docker build -t reproduce-trace-issues:v1 .
```

## Run the image

```
docker run --rm -ti --env APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>" \
                    --env APPLICATIONINSIGHTS_SELF_DIAGNOSTICS_LEVEL="TRACE" \
                    --env JAVA_TOOL_OPTIONS="-javaagent:/tmp/applicationinsights-agent.jar" \
                    reproduce-trace-issues:v1
```
