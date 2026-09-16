package com.datasqrl.testjobs;

import org.apache.flink.table.functions.FunctionContext;
import org.apache.flink.table.functions.ScalarFunction;

/**
 * Keeps a batch job in RUNNING for a fixed wall-clock duration, then fails it.
 *
 * <p>The deadline is wall-clock from {@link #open}, not a per-row or per-subtask budget, so the
 * runtime before failure is the same whatever parallelism or row count the job ends up with.
 */
public class FailAfterDelay extends ScalarFunction {

  private static final long POLL_MILLIS = 5_000L;

  private long openedAtMillis;

  /** Constant-folding would move the failure into planning, i.e. a compile error, not a job run. */
  @Override
  public boolean isDeterministic() {
    return false;
  }

  @Override
  public void open(FunctionContext ctx) {
    openedAtMillis = System.currentTimeMillis();
  }

  public Long eval(Long value, Integer runSeconds) {
    var deadline = openedAtMillis + runSeconds * 1000L;

    for (var remaining = deadline - System.currentTimeMillis();
        remaining > 0;
        remaining = deadline - System.currentTimeMillis()) {
      try {
        Thread.sleep(Math.min(remaining, POLL_MILLIS));
      } catch (InterruptedException e) {
        // A cancel or terminate must not wait out the remaining delay.
        Thread.currentThread().interrupt();
        return value;
      }
    }

    throw new RuntimeException(
        "FailAfterDelay: failing deliberately after " + runSeconds + "s of runtime");
  }
}
