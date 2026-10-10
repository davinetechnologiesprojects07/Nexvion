# Nexvion Troubleshooting Documentation

## Kubernetes Node NotReady
After Docker Desktop restarted, the Kind control-plane IP changed while kubelet still referenced the previous API-server IP.
The kubelet endpoint was corrected and kubelet restarted, returning the node to Ready state.

## Elasticsearch Slow Startup
Local resource constraints caused slow Elasticsearch startup. Resources were temporarily freed and Elasticsearch CPU allocation increased.

## Logstash Permission Issue
Logstash initially could not read Kubernetes container log files. Supplemental group permissions were added to allow log collection.

## Kibana Access
Kibana was exposed locally through a Docker reverse proxy when Windows-to-WSL port forwarding was unreliable.

## GitHub Authentication
GitHub password authentication is not supported for HTTPS Git operations. Authenticated Git Bash credentials or a personal access token should be used.
