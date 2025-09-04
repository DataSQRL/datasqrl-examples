//DEPS org.apache.flink:flink-table-common:1.19.3

import org.apache.flink.table.functions.ScalarFunction;

public class MyScalarFunction extends ScalarFunction {

  public long eval(long a, long b) {
    return a + b;
  }
}
