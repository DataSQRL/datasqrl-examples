///usr/bin/env jbang "$0" "$@" ; exit $?

import org.apache.flink.table.functions.ScalarFunction;

public class MyScalarFunction extends ScalarFunction {

  public long eval(long a, long b) {
    return a + b;
  }
}
