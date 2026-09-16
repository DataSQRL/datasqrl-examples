package com.datasqrl.testjobs;

import org.apache.flink.table.functions.FunctionContext;
import org.apache.flink.table.functions.ScalarFunction;

/**
 * Fails one subtask while its siblings refuse to cancel, so the job sits in FAILING with a vertex
 * aggregated as FAILED for a measurable window.
 *
 * <p>A plain terminal failure is unobservable: the vertex is FAILED for a second or two and the
 * JobManager exits with it, so {@code status-counts} is never read in that state. Flink aggregates
 * a vertex as FAILED as soon as any subtask is, and cannot finish failing until the rest cancel —
 * so sibling subtasks that ignore interruption hold that state open.
 *
 * <p>The grace must stay under {@code task.cancellation.timeout} (180s default), past which Flink
 * kills the TaskManager outright and the window closes early.
 */
public class FailOneSubtaskSlowCancel extends ScalarFunction {

  private static final long POLL_MILLIS = 2_000L;
  private static final long FAILING_ID = 1L;

  private long openedAtMillis;
  private boolean graceSpent;

  @Override
  public boolean isDeterministic() {
    return false;
  }

  @Override
  public void open(FunctionContext ctx) {
    openedAtMillis = System.currentTimeMillis();
    graceSpent = false;
  }

  public Long eval(Long value, Integer runSeconds, Integer graceSeconds) {
    awaitInterruptibly(openedAtMillis + runSeconds * 1000L);

    if (value != null && value == FAILING_ID) {
      throw new RuntimeException(
          "FailOneSubtaskSlowCancel: failing the subtask holding id="
              + FAILING_ID
              + " after "
              + runSeconds
              + "s, siblings hold cancellation for "
              + graceSeconds
              + "s");
    }

    if (!graceSpent) {
      graceSpent = true;
      resistCancellation(graceSeconds * 1000L);
    }
    return value;
  }

  private static void awaitInterruptibly(long deadlineMillis) {
    for (var remaining = deadlineMillis - System.currentTimeMillis();
        remaining > 0;
        remaining = deadlineMillis - System.currentTimeMillis()) {
      try {
        Thread.sleep(Math.min(remaining, POLL_MILLIS));
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        return;
      }
    }
  }

  private static void resistCancellation(long durationMillis) {
    var deadline = System.currentTimeMillis() + durationMillis;
    while (System.currentTimeMillis() < deadline) {
      try {
        Thread.sleep(POLL_MILLIS);
      } catch (InterruptedException e) {
        // Swallowed on purpose: the interrupt is Flink cancelling us, and holding it open is
        // exactly what keeps the failed vertex readable.
      }
    }
  }
}
