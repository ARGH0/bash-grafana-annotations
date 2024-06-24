# bash-grafana-annotations
Bash scripts to use to the grafana annotations API
https://grafana.com/docs/grafana/latest/developers/http_api/annotations/

I use these scripts to do CRUD actions on the grafana annotations within my pipelines

--- How to use the scripts:

# addAnnotation.sh

## Introduction
`addAnnotation.sh` is a script designed to automate the process of adding annotations to Grafana. Annotations in Grafana allow users to mark points on the graph with rich event descriptions. This script simplifies adding these annotations by utilizing various deployment-related parameters.

## Parameters
The script accepts the following parameters:

- `grafana_server`: URL of the Grafana server.
- `grafana_token`: Authorization token for the Grafana API.
- `kind`: Kind of the deployment pipeline (e.g., 'deployment', 'build').
- `type`: Type of the infrastructure (e.g., 'infrastructure', 'application').
- `environment`: Deployment environment (e.g., 'production', 'staging', 'development').
- `build_number`: Unique build number of the deployment.
- `component`: Component being deployed (optional).
- `image_tag`: Docker image tag of the component being deployed (optional).
- `collection`: Logical grouping of related components (optional).

## How It Works
The script operates by building tags and text for the annotation based on the provided parameters. It utilizes two helper functions, `build_tags` and `build_text`, to generate the tags and text, respectively.

### build_tags Function
Generates tags for the annotation using the provided parameters. The first four parameters (`kind`, `type`, `environment`, `build_number`) are always used, while the last three (`component`, `image_tag`, `collection`) are optional and included if provided.

### build_text Function
Creates a descriptive text for the deployment based on the `type` parameter. The outcome varies depending on the values of `kind` and `type`, providing specific deployment information.

## Example Usage
```bash
bash /path/to/addAnnotations.sh "http://localhost:3000" "your_grafana_token" "deployment" "infrastructure" "production" "123" "web-server" "v1.0.0" "web-servers"
```

This command will add an annotation to Grafana with the tags kind:deployment, type:infrastructure, env:production, build:123, component:web-server, image:v1.0.0, and collection:web-servers. The text of the annotation will be built by the build_text function in the addAnnotation.sh script.

# patchAnnotations.sh

## Overview
`patchAnnotations.sh` is a Bash script designed to update annotations in Grafana. Annotations in Grafana are used to mark points on the graph with rich events. This script facilitates the automation of updating these annotations based on various deployment-related parameters.

## Parameters

The script accepts several parameters:

- `grafana_server`: The URL of the Grafana server.
- `grafana_token`: The authorization token for the Grafana API.
- `kind`: The kind of the deployment pipeline, such as 'deployment', 'build', etc.
- `type`: The type of the infrastructure, such as 'infrastructure', 'application', etc.
- `environment`: The environment where the deployment is happening, such as 'production', 'staging', 'development', etc.
- `build_number`: The build number of the deployment, serving as a unique identifier for each build.
- `component`: The component being deployed (optional), which could be the name of the microservice or application.
- `image_tag`: The image tag of the component being deployed (optional), typically the Docker image tag.
- `collection`: The collection to which the component belongs (optional), representing a logical grouping of related components.

## How it Works

1. The script begins by constructing the URI for the annotation using the `build_annotation_uri` function with the provided parameters. This function builds the URI by appending tags for `kind`, `type`, `environment`, `build_number`, `component`, `image_tag`, and `collection` to the base Grafana API URL.

2. Once the URI is constructed, the script sends a GET request to fetch the annotation.

3. If the response is empty, indicating no annotations were found for the given tags, the script prints a message and exits.

4. If the response contains multiple annotations, suggesting there are multiple annotations for the given tags, the script prints a message and exits.

5. If a single annotation is found, the script updates the `timeEnd` of the annotation to the current time and sends a PATCH request to the Grafana API to update the annotation with the new `timeEnd`.

## Example Usage

```bash
bash /path/to/patchAnnotations.sh "http://localhost:3000" "your_grafana_token" "deployment" "infrastructure" "production" "123" "web-server" "v1.0.0" "web-servers"
```

This command sends a GET request to the Grafana API to fetch an annotation with the tags kind:deployment, type:infrastructure, env:production, build:123, component:web-server, image:v1.0.0, and collection:web-servers. The script then processes the response and updates the annotation as necessary. ```
