# Nexvion AI-Assisted Incident Analysis

## Incident
Kubernetes workloads became unavailable after Docker Desktop restarted and the
Kind control-plane container received a new IP address.

## Observed Error
The Kubernetes node remained NotReady and kubelet attempted to contact the old
API server address:

https://172.18.0.5:6443

The actual Kind control-plane address had changed to:

172.18.0.3

## AI-Assisted Classification
Category: Kubernetes networking / control-plane connectivity issue

## Severity
High

Reason:
The Kubernetes node could not register with the API server, affecting application,
monitoring and logging workloads.

## Probable Root Cause
Docker Desktop restart changed the IP address assigned to the Kind control-plane
container. Kubernetes kubelet configuration still referenced the previous API
server IP.

## Investigation Suggested
1. Check Docker container IP.
2. Compare it with Kubernetes node Internal-IP.
3. Review kubelet logs.
4. Verify kubelet.conf API server endpoint.
5. Confirm API server health.

## Remediation
The API server endpoint in kubelet.conf was updated from the old IP to the new
Kind control-plane IP and kubelet was restarted.

## Result
The node successfully re-registered and returned to Ready state.

ELK, Helm and Nexvion workloads were subsequently restored and verified.

## AI Role
AI was used to:
- Classify the error.
- Determine incident severity.
- Identify probable root cause.
- Suggest investigation steps.
- Recommend remediation actions.

Final actions were validated using actual Kubernetes and Docker command outputs.
