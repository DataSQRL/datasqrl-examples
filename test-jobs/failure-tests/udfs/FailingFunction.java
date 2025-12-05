//DEPS org.apache.flink:flink-table-common:1.19.3

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
