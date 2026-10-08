#!/usr/bin/env python3
"""AI-assisted incident analysis for Nexvion logs stored in Elasticsearch.

Pulls recent error events, summarizes them, and produces: classification,
severity, probable root cause, investigation steps and remediation.
Backends: rules (offline), ollama (local model), anthropic (hosted API).
"""
import argparse, collections, datetime, json, os, re, sys, urllib.request

ES = os.environ.get("ES_URL", "http://localhost:9200")
IP = re.compile(r"\b\d{1,3}(?:\.\d{1,3}){3}\b")


def http_json(url, payload=None, headers=None, timeout=120):
    data = json.dumps(payload).encode() if payload is not None else None
    hdrs = {"Content-Type": "application/json"}
    hdrs.update(headers or {})
    req = urllib.request.Request(url, data=data, headers=hdrs)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.load(resp)


def fetch_events(minutes, size=300):
    body = {
        "size": size,
        "sort": [{"@timestamp": "desc"}],
        "_source": ["@timestamp", "message", "response", "request", "verb", "container.name", "log_type"],
        "query": {"bool": {
            "filter": [{"range": {"@timestamp": {"gte": f"now-{minutes}m"}}}],
            "should": [
                {"range": {"response": {"gte": 400}}},
                {"query_string": {"query": "message:(error OR exception OR failed OR refused OR denied OR timeout OR \"Cannot allocate\")"}},
            ],
            "minimum_should_match": 1,
        }},
    }
    hits = http_json(f"{ES}/nexvion-logs-*/_search", body)["hits"]["hits"]
    return [h["_source"] for h in hits]


def count_access(minutes):
    body = {"query": {"bool": {"filter": [
        {"match": {"log_type": "access"}},
        {"range": {"@timestamp": {"gte": f"now-{minutes}m"}}},
    ]}}}
    return http_json(f"{ES}/nexvion-logs-*/_count", body)["count"]


def summarize(events, total_access, minutes):
    statuses = collections.Counter()
    paths = collections.defaultdict(collections.Counter)
    containers = collections.Counter()
    samples = []
    for e in events:
        cname = (e.get("container") or {}).get("name", "unknown")
        containers[cname] += 1
        status = e.get("response")
        if status:
            statuses[int(status)] += 1
            paths[int(status)][e.get("request", "?")] += 1
        elif len(samples) < 8:
            samples.append(f"[{cname}] {e.get('message', '')[:220]}")
    errors = sum(statuses.values())
    return {
        "window_minutes": minutes,
        "events_analyzed": len(events),
        "access_requests": total_access,
        "http_errors": errors,
        "error_ratio": round(errors / total_access, 3) if total_access else 0,
        "status_counts": dict(sorted(statuses.items())),
        "top_paths": {str(s): dict(c.most_common(5)) for s, c in paths.items()},
        "containers": dict(containers),
        "log_samples": samples,
    }


def analyze_rules(s):
    findings = []
    sc = {int(k): v for k, v in s["status_counts"].items()}
    gw = sum(v for k, v in sc.items() if k in (502, 503, 504))
    other5 = sum(v for k, v in sc.items() if 500 <= k < 600) - gw
    n404 = sc.get(404, 0)
    authz = sc.get(401, 0) + sc.get(403, 0)
    text = " ".join(s["log_samples"]).lower()

    if gw:
        sev = "critical" if s["error_ratio"] >= 0.5 else "high"
        findings.append({
            "classification": "Upstream / gateway failure (HTTP 502/503/504)", "severity": sev,
            "evidence": f"{gw} gateway errors, error ratio {s['error_ratio']}",
            "probable_root_cause": "The backend behind the proxy is down, restarting or unreachable.",
            "investigation_steps": ["docker ps / kubectl get pods to see whether the backend is running",
                                    "Check proxy error logs for 'connect() failed' or 'upstream' messages",
                                    "Check backend health endpoint (/healthz) and recent restarts",
                                    "Correlate the first error timestamp with the last deployment"],
            "remediation": ["Restart or redeploy the backend", "Roll back the last release if errors began after a deploy",
                            "Add readiness probes / alerts on 5xx ratio"]})
    if other5 > 0:
        findings.append({
            "classification": "Application server error (HTTP 5xx)", "severity": "high",
            "evidence": f"{other5} server errors",
            "probable_root_cause": "Unhandled error in the application or its configuration.",
            "investigation_steps": ["Read application error log around the first 5xx", "Check last config or image change"],
            "remediation": ["Fix or roll back the faulty release"]})
    if re.search(r"refused|connect\(\) failed", text) and not gw:
        findings.append({
            "classification": "Connection refused", "severity": "high", "evidence": "log lines mention refused connections",
            "probable_root_cause": "A dependency is not listening on the expected host/port.",
            "investigation_steps": ["Verify the target service is running and its port", "Check network/firewall rules"],
            "remediation": ["Start or fix the dependency", "Add retry/backoff and health checks"]})
    if re.search(r"cannot allocate memory|outofmemory|oom", text):
        findings.append({
            "classification": "Resource exhaustion (memory)", "severity": "high", "evidence": "out-of-memory messages in logs",
            "probable_root_cause": "Host or container memory limit reached.",
            "investigation_steps": ["free -h / kubectl top pods", "Check container memory limits"],
            "remediation": ["Increase limits or free memory", "Reduce heap sizes / replicas"]})
    if re.search(r"java \d+.*minimum required|unsupported (class|major)", text):
        findings.append({
            "classification": "Runtime version incompatibility", "severity": "medium",
            "evidence": "Java version error in logs",
            "probable_root_cause": "The runtime in the image is older than the application requires.",
            "investigation_steps": ["Compare required and installed runtime versions"],
            "remediation": ["Use a base image with the required runtime"]})
    if authz:
        findings.append({
            "classification": "Authorization / authentication errors (401/403)", "severity": "medium",
            "evidence": f"{authz} auth errors",
            "probable_root_cause": "Missing credentials, expired tokens or blocked access.",
            "investigation_steps": ["Check which paths and clients trigger them"],
            "remediation": ["Review access rules and credentials"]})
    if n404:
        spread = len(s["top_paths"].get("404", {}))
        findings.append({
            "classification": "Missing resource requests (HTTP 404)",
            "severity": "medium" if n404 >= 10 and spread >= 5 else "low",
            "evidence": f"{n404} not-found responses across {spread}+ paths",
            "probable_root_cause": "Broken links, removed pages or scanning for unknown paths.",
            "investigation_steps": ["Review the top requested missing paths", "Check referrers for broken internal links"],
            "remediation": ["Fix or redirect broken links", "Rate-limit clients that scan many paths"]})
    order = {"low": 0, "medium": 1, "high": 2, "critical": 3}
    findings.sort(key=lambda f: order[f["severity"]], reverse=True)
    return findings or [{"classification": "No significant errors", "severity": "low",
                         "evidence": "no matching error patterns in the window"}]


PROMPT = """You are a DevOps incident analysis assistant for the Nexvion e-commerce platform
(nginx static frontend running in Docker/Kubernetes, logs stored in Elasticsearch).
Analyze the log summary below and reply with ONLY a JSON object with these keys:
"classification" (short error category), "severity" (low|medium|high|critical),
"probable_root_cause" (string), "investigation_steps" (list of 3-5 concrete steps),
"remediation" (list of 2-4 concrete actions), "confidence" (low|medium|high).
Base your answer only on the evidence. If the evidence is insufficient, say so.

LOG SUMMARY:
{summary}
"""


def redact(text):
    return IP.sub("x.x.x.x", text)


def ask_ollama(prompt):
    url = os.environ.get("OLLAMA_URL", "http://localhost:11434")
    model = os.environ.get("OLLAMA_MODEL", "llama3.2:3b")
    r = http_json(f"{url}/api/generate", {"model": model, "prompt": prompt, "stream": False, "format": "json"}, timeout=600)
    return r["response"]


def ask_anthropic(prompt):
    key = os.environ["ANTHROPIC_API_KEY"]
    model = os.environ.get("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001")
    r = http_json("https://api.anthropic.com/v1/messages",
                  {"model": model, "max_tokens": 1000, "messages": [{"role": "user", "content": prompt}]},
                  headers={"x-api-key": key, "anthropic-version": "2023-06-01"})
    return "".join(b.get("text", "") for b in r["content"])


def analyze_ai(summary, backend):
    prompt = PROMPT.format(summary=redact(json.dumps(summary, indent=2)))
    raw = ask_ollama(prompt) if backend == "ollama" else ask_anthropic(prompt)
    match = re.search(r"\{.*\}", raw, re.S)
    try:
        return json.loads(match.group(0)) if match else {"raw_response": raw}
    except json.JSONDecodeError:
        return {"raw_response": raw}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--minutes", type=int, default=120, help="look-back window")
    ap.add_argument("--backend", choices=["rules", "ollama", "anthropic"], default="rules")
    args = ap.parse_args()

    events = fetch_events(args.minutes)
    summary = summarize(events, count_access(args.minutes), args.minutes)
    report = {"generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "summary": summary, "rules_analysis": analyze_rules(summary)}
    if args.backend != "rules":
        report["ai_analysis"] = {"backend": args.backend, "result": analyze_ai(summary, args.backend)}

    out = json.dumps(report, indent=2)
    print(out)
    os.makedirs("ai/reports", exist_ok=True)
    path = f"ai/reports/incident-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}-{args.backend}.json"
    with open(path, "w") as fh:
        fh.write(out)
    print(f"\nReport saved to {path}", file=sys.stderr)


if __name__ == "__main__":
    main()
