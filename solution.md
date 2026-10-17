# Capstone 2: Site Reliability Engineering (SRE) Solution

## 1. Introduction

The Example Voting App is a distributed application that allows users to submit votes and view results. Its components include a voting frontend, a results frontend, a worker service, PostgreSQL for persistent storage, and Redis for message handling.

This document evaluates the application from a Site Reliability Engineering (SRE) perspective and proposes improvements to reliability, performance, monitoring, security, and resource efficiency.

The recommendations are proposed targets and improvements, not claims of measured production performance or a completed live Kubernetes deployment.

## 2. Observed Architecture and Potential Improvements

The application consists of several services that depend on one another. A failure in Redis, PostgreSQL, or the worker can affect vote processing and result display.

Recommended improvements include:

- **Availability:** Configure health checks, readiness probes, liveness probes, and restart policies. Use multiple replicas for critical stateless services in Kubernetes.
- **Data reliability:** Use persistent PostgreSQL storage, scheduled backups, and regularly tested restoration procedures.
- **Dependency resilience:** Configure connection timeouts, exponential-backoff retries, and graceful error handling. Avoid unlimited retries that could overload a recovering service.
- **Security:** Store credentials in Kubernetes Secrets or a dedicated secret manager, restrict service permissions, scan container images, and maintain supported dependencies and runtime versions.
- **Deployment safety:** Use rolling updates, readiness checks, versioned images, and documented rollback procedures.
- **Scalability:** Scale stateless frontend services according to measured demand. Monitor database capacity and queue processing before scaling dependent components.

## 3. Service Level Indicators (SLIs)

An SLI is a quantitative measurement of service performance or reliability.

| SLI | Measurement |
| --- | --- |
| Availability | Percentage of valid requests completed successfully |
| Latency | Request completion time, including p95 and p99 latency |
| Vote processing | Percentage of accepted votes processed successfully |
| Result freshness | Time between a vote being accepted and appearing in results |
| Error rate | Percentage of requests returning server errors |
| Resource utilization | CPU, memory, storage, and database connection usage |

Measurements should be collected over a defined time window and segmented by service where necessary. Health-check requests should not hide failures experienced by users.

## 4. Service Level Objectives (SLOs)

An SLO is an internal reliability target over a defined period. The following are proposed initial targets that should be reviewed after collecting a baseline under realistic workloads.

| Indicator | Proposed SLO |
| --- | --- |
| Successful voting requests | At least 99.5% per calendar month |
| Voting request latency | 95% of requests complete within 500 ms |
| Result request latency | 95% of requests complete within 500 ms |
| Vote processing | At least 99% of accepted votes processed within 60 seconds |
| Recovery | Restore critical service within a proposed 30-minute target |

Latency and processing targets should be validated through load testing. Recovery time depends on the failure scenario, backups, and recovery procedures. It must be tested before being treated as an achieved target.

## 5. Service Level Agreements (SLAs)

An SLA is an external agreement defining service commitments to users or customers, including possible consequences when commitments are not met.

The proposed 99.5% monthly availability SLO is an internal engineering target, not an established customer SLA.

If the application were offered as a production service, its owner could define an SLA based on measured reliability, support arrangements, planned maintenance, exclusions, and appropriate remedies. Any SLA should be approved and documented before being communicated as a commitment.

## 6. Error Budgets

An error budget is the amount of unreliability permitted by an SLO.

With a proposed monthly availability SLO of 99.5%, the error budget is 0.5% of the measurement period.

For a 30-day month:

- Total time: 43,200 minutes.
- Allowed unavailability at 0.5%: 216 minutes.
- Equivalent downtime budget: 3 hours and 36 minutes.

This is an illustrative time-based calculation. If availability is measured using successful requests, the error budget should instead be calculated from eligible request counts and the SLO.

The team should review error-budget consumption regularly. When the budget is being consumed too quickly, reliability work should take priority and high-risk releases may need to be delayed until service stability improves.

## 7. Monitoring and Observability

Observability helps engineers understand an application's internal state through metrics, logs, and traces.

### Metrics

Monitor:

- Request rate, latency, and error rate for vote and result services.
- Worker processing rate, failures, and queue backlog.
- PostgreSQL availability, active connections, storage capacity, and query performance.
- Redis availability, memory usage, and connection failures.
- Container CPU and memory utilization, restarts, and failed health checks.

### Logs

Use structured logs with timestamps, severity levels, service names, and correlation identifiers where possible. Avoid recording passwords, tokens, or other sensitive information.

### Tracing

Distributed tracing can help identify slow requests and delays across the frontend, worker, Redis, and PostgreSQL components. Instrumentation should be added where the architecture supports it.

### Alerting

Configure actionable alerts for sustained high error rates, breached latency targets, unavailable dependencies, growing processing backlogs, and low storage capacity. Alerts should include relevant context and runbook links.

Prometheus and Grafana are suitable options for metrics and dashboards. A centralized logging system can help investigate failures. These tools are recommendations and are not claimed to be deployed in this project.

## 8. Incident Response and Recovery

A documented incident process should include:

1. Detect the problem through monitoring or a user report.
2. Assess its impact on voting, result display, and vote processing.
3. Identify the affected component using metrics and logs.
4. Mitigate the problem, for example by rolling back a faulty release or restoring a failed dependency.
5. Verify service recovery and confirm that accepted votes have not been lost.
6. Document the cause, timeline, corrective actions, and lessons learned.

Database backups should be scheduled according to the required recovery objectives. The recovery point objective (RPO) defines how much data loss is acceptable, while the recovery time objective (RTO) defines how quickly the service should be restored. Appropriate values must be selected and validated through restoration exercises.

## 9. Resource and Cost Efficiency

The following practices can improve resource efficiency:

- Establish CPU and memory baselines before selecting container resource requests and limits.
- Scale stateless services according to demand, using autoscaling only after suitable metrics and thresholds are established.
- Review database queries, connection pooling, and indexes to avoid unnecessary resource consumption.
- Remove unused images and build artifacts, and use appropriate multi-stage Docker builds.
- Use lightweight, supported base images and regularly scan dependencies.
- Review cloud resource costs and avoid provisioning infrastructure that is not required.
- Test performance under realistic workloads before increasing capacity.

Cost optimization should not compromise data durability, security, or reliability objectives.

## 10. CI/CD and Release Reliability

The repository's GitHub Actions pipeline provides automated integration testing and image build, scanning, and publishing steps.

Further improvements include:

- Run tests before publishing container images.
- Review vulnerability scan results and establish a process for addressing critical and high-severity findings.
- Use immutable image tags tied to a commit rather than relying only on mutable tags such as `latest`.
- Deploy progressively where a deployment environment is available.
- Verify application health after deployment and maintain a documented rollback procedure.
- Protect credentials using GitHub Actions secrets or an appropriate identity-based authentication mechanism.

A successful CI run demonstrates that the configured workflow passed. It does not by itself prove production availability, zero vulnerabilities, or a successful live deployment.

## 11. Implementation Roadmap

### Immediate priorities

- Keep application dependencies and container images maintained.
- Preserve automated integration tests and image scanning.
- Document service dependencies, health checks, and recovery procedures.
- Establish baseline latency, error-rate, and resource measurements.

### Next steps

- Add production-oriented dashboards and actionable alerts.
- Configure and test persistent database backups and restoration.
- Validate the proposed SLOs using load and failure testing.
- Review resource requirements and scaling behavior.

### Longer-term improvements

- Introduce distributed tracing and more detailed service-level monitoring.
- Test controlled failure scenarios and disaster-recovery procedures.
- Implement progressive deployments and automated rollback where appropriate.
- Review SLOs and error-budget policies using real operational data.

## 12. Conclusion

The Example Voting App can benefit from measurable reliability objectives, strong monitoring, resilient dependency handling, secure configuration, tested recovery procedures, and efficient resource management.

The proposed SLIs, SLOs, error-budget policy, and improvement roadmap provide a basis for evaluating the application from an SRE perspective. The numerical targets are proposals that require validation through testing and operational measurements. They should not be interpreted as proof that the application has achieved those reliability levels or has been deployed to a live Kubernetes or AWS environment.
