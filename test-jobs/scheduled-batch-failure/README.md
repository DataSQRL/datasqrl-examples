# scheduled-batch-failure

A scheduled batch job that stays in `RUNNING` for a fixed wall-clock duration and then fails
terminally. It exists to exercise the *failure* half of the scheduled-batch lifecycle, which the
existing test jobs never reach — `scheduled-batch-stress` only ever finishes successfully.

`FAILED` and `FINISHED` are both in cloud-compilation's `TERMINAL_JOB_STATES`, so the batch tracker
is expected to sleep a failed run exactly like a successful one. Whether anything downstream
distinguishes the two is what this job is for.

## Shape

`failing_batch.sqrl` is `scheduled-batch-stress`'s script plus a tripwire:

```sql
Items := SELECT id, name FROM DummyInput WHERE FailAfterDelay(id, 600) >= 0;
```

`FailAfterDelay` blocks until 600s after the function opened, then throws. Two details matter:

- The deadline is wall-clock from `open()`, not a per-row or per-subtask budget, so the job runs for
  the same 10 minutes at any parallelism or row count.
- The call sits in a `WHERE`, not a projection. A projected column that nothing consumes is pruned
  by the planner and the failure would never run. `isDeterministic() = false` likewise keeps the
  planner from constant-folding the call into a *compile* error.

Change the duration by editing the second argument; the jar does not need rebuilding.

`restart-strategy.type: none` makes the first failure terminal. Without it the job would restart and
burn another full duration, repeatedly.

## The UDF jar is committed on purpose

`udfs/fail-after-delay.jar` is checked in, and `udfs/FailAfterDelay.java` deliberately carries **no**
JBang shebang. `JBangPreprocessor` silently skips `.java` sources when no JBang toolchain is present,
which would leave the compile without the function; `JarPreprocessor` picks the committed jar up from
its `META-INF/services` entry with no toolchain at all. Rebuild with `udfs/build-udf.sh` after
editing the source.

## Verifying

`local_fail.sqrl` + `local-package.json` are a flink-only, 60s variant for exactly this check — no
postgres or vertx, so it needs nothing but the image:

```bash
docker run --rm -v "$PWD:/workspace" datasqrl/cmd:0.11.5 run local-package.json
```

The run should take just over 60s and end in
`RuntimeException: FailAfterDelay: failing deliberately after 60s of runtime`. A run that ends in
about a second means the call was pruned or folded.
