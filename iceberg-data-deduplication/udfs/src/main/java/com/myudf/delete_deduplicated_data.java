/*
 * Copyright © 2021 DataSQRL (contact@datasqrl.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.myudf;

import com.google.auto.service.AutoService;
import java.util.Map;
import java.util.function.Function;
import javax.annotation.Nullable;
import org.apache.flink.table.annotation.DataTypeHint;
import org.apache.flink.table.functions.ScalarFunction;
import org.apache.iceberg.Table;

@AutoService(ScalarFunction.class)
public class delete_deduplicated_data extends ScalarFunction {

  public boolean eval(
      String warehouse,
      @Nullable String catalogType,
      String catalogName,
      @Nullable String databaseName,
      String tableName,
      String partitionCol,
      Long maxTimeBucket,
      @DataTypeHint("MULTISET<BIGINT>") Map<Long, Integer> partitionIds) {

    if (warehouse == null
        || catalogName == null
        || tableName == null
        || partitionCol == null
        || maxTimeBucket == null
        || partitionIds == null
        || partitionIds.isEmpty()) {
      return false;
    }

    var delFn = getDeleteFunction(partitionCol, partitionIds.keySet().toArray(), maxTimeBucket);
    CatalogUtils.executeInCatalog(
        warehouse, catalogType, catalogName, databaseName, tableName, delFn);

    return true;
  }

  private Function<Table, Void> getDeleteFunction(
      String partitionIdCol, Object[] partitionIdVals, Long maxTimeBucket) {

    return table -> {
      var delExpr =
          ExpressionUtils.buildPartitionDelete(partitionIdCol, partitionIdVals, maxTimeBucket);
      var delFiles = table.newDelete().deleteFromRowFilter(delExpr);
      delFiles.commit();

      return null;
    };
  }
}
