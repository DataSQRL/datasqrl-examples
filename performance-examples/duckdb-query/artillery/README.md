# Artillery GraphQL Load Test

This directory contains Artillery load tests for the DataSQRL GraphQL API.

## Prerequisites

Install Artillery:
```bash
npm install -g artillery@latest
```

## Running the Test

Basic run:
```bash
npm test
```

## Test Configuration

- **Target**: `http://localhost:8888`
- **Duration**: 60 seconds
- **Rate**: 10 queries per second
- **Query**: MetricsByTime with random machineid (1-99)

## Metrics Reported

Artillery will report:
- **Latency percentiles**: p50, p75, p90, p95, p99
- **Request rate**: requests per second
- **Error rate**: percentage of failed requests
- **Response codes**: distribution of HTTP status codes
- **Scenarios completed**: number of successful test scenarios

## Performance Thresholds

The test includes assertions:
- Max error rate: 1%
- p95 latency: < 1000ms
- p99 latency: < 2000ms

## Customization

Edit `graphql-load-test.yml` to:
- Change load pattern (phases)
- Modify query variables
- Adjust performance thresholds
- Add more scenarios
