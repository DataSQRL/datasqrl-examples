# Long-lived test jobs

The cloud-frontend E2E suite keeps one deployment of each job running in the E2E data group and
checks on every run that it is still healthy, so infrastructure updates that break existing
deployments fail the suite.

* [Streaming](long-lived-streaming.sqrl): datagen emits one heartbeat per second, the API serves the latest one per sensor and the heartbeat count of every minute in the last 30 days
* [Batch](long-lived-batch.sqrl): runs every 3 hours (`0 */3 * * *`, UTC) and writes a count to Postgres

Both jobs use the `dev` sizes with a CPU request factor of 0.1 to keep running them around the clock
cheap.

A change here reaches the running deployments only when they are recreated: delete the project in
the E2E data group and the next E2E run deploys it again. The batch cron is mirrored in
`LONG_LIVED_BATCH_PROJECT` in cloud-frontend's `e2e/constants/projects.ts`.
