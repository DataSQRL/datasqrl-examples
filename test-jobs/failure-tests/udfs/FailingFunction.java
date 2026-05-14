///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS org.apache.flink:flink-table-common:2.2.0

import org.apache.flink.table.functions.FunctionContext;
import org.apache.flink.table.functions.ScalarFunction;

public class FailingFunction extends ScalarFunction {

  @Override
  public void open(FunctionContext ctx) {
    throw new RuntimeException("UDF init failed");
  }

  public String eval(String s) {
    return s;
  }
}
