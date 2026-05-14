///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS org.apache.flink:flink-table-common:2.2.0

import org.apache.flink.table.functions.ScalarFunction;

public class MyScalarFunction extends ScalarFunction {

  public long eval(long a, long b) {
    return a + b;
  }
}
