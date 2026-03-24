/*
 * Copyright © 2025 DataSQRL (contact@datasqrl.com)
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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import javax.annotation.Nullable;
import org.apache.flink.table.annotation.DataTypeHint;
import org.apache.flink.table.functions.ScalarFunction;
import org.apache.iceberg.PartitionField;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.apache.iceberg.PartitionSpec;
import org.apache.iceberg.Table;
import org.apache.iceberg.expressions.Expression;
import org.apache.iceberg.expressions.Expressions;
import org.apache.iceberg.types.Type;

@AutoService(ScalarFunction.class)
public class delete_duplicated_data extends ScalarFunction {

  private static final Logger LOG = LoggerFactory.getLogger(delete_duplicated_data.class);

  private static final String DEFAULT_TIME_BUCKET = "time_bucket";

  /**
   * Deletes duplicated data from an Iceberg table based on partition specifications and time bucket constraints.
   *
   * @param warehouse The warehouse path or URI for the catalog
   * @param catalogType The type of catalog (optional, e.g., "hadoop", "hive")
   * @param catalogName The name of the catalog
   * @param databaseName The database/schema name (optional)
   * @param maxTimeBucket The maximum time bucket value (inclusive) for records to delete
   * @param tablePartitionSet Set of table partition specifications where each map contains
   *                          tableName -> Map(partitionColName -> partitionValue) mappings.
   * @return true if deletion was successful for all tables, false if any failed
   */
  public boolean eval(
      String warehouse,
      @Nullable String catalogType,
      String catalogName,
      @Nullable String databaseName,
      Long maxTimeBucket,
      @DataTypeHint("MULTISET<MAP<STRING, MAP<STRING, STRING>>>") Map<Map<String, Map<String,String>>, Integer> tablePartitionSet) {

    var invalid = new ArrayList<String>();
    if (warehouse == null) invalid.add("warehouse");
    if (catalogName == null) invalid.add("catalogName");
    if (maxTimeBucket == null) invalid.add("maxTimeBucket");
    if (tablePartitionSet == null) invalid.add("tablePartitionSet is null");
    else if (tablePartitionSet.isEmpty()) invalid.add("tablePartitionSet is empty");
    if (!invalid.isEmpty()) {
      LOG.warn("Invalid arguments: {}", invalid);
      return false;
    }

    // Group partition col name -> value mappings by table name
    Map<String, Set<Map<String, String>>> partitionsByTable = new HashMap<>();
    for (var entry : tablePartitionSet.keySet()) {
      for (var tableEntry : entry.entrySet()) {
        String tableName = tableEntry.getKey();
        Map<String, String> partitionMap = tableEntry.getValue();
        partitionsByTable
            .computeIfAbsent(tableName, k -> new HashSet<>())
            .add(partitionMap == null ? Map.of() : partitionMap);
      }
    }

    try {
      for (var tableEntry : partitionsByTable.entrySet()) {
        String tableName = tableEntry.getKey();
        Set<Map<String, String>> partitionMaps = tableEntry.getValue();

        // Collect all partition column names for this table
        var partitionCols = new HashSet<String>();
        for (var pm : partitionMaps) {
          partitionCols.addAll(pm.keySet());
        }

        final var finalPartitionCols = partitionCols;
        final var finalPartitionMaps = partitionMaps;

        Function<Table, Boolean> delFn =
            table -> {
              var spec = table.spec();
              var timeBucketCol = findTimeBucketColumn(spec, finalPartitionCols);

              if (timeBucketCol == null) {
                return false;
              }

              var delExpr = buildGeneralizedPartitionDelete(
                  spec, finalPartitionMaps, timeBucketCol, maxTimeBucket);

              var delFiles = table.newDelete().deleteFromRowFilter(delExpr);
              delFiles.commit();

              return true;
            };

        boolean result = CatalogUtils.executeInCatalog(
            warehouse, catalogType, catalogName, databaseName, tableName, delFn);
        if (!result) {
          return false;
        }
      }

      return true;

    } catch (Exception e) {
      LOG.warn("Failed to delete partitions", e);
      return false;
    }
  }

  private String findTimeBucketColumn(PartitionSpec spec, Set<String> partitionColumns) {
    // Handle unpartitioned tables
    if (spec.isUnpartitioned()) {
      return null;
    }

    var allPartitionFields = new HashSet<String>();
    for (PartitionField field : spec.fields()) {
      allPartitionFields.add(field.name());
    }

    // Find the time bucket column by removing known partition columns
    var remainingFields = new HashSet<>(allPartitionFields);
    remainingFields.removeAll(partitionColumns);

    if (remainingFields.size() == 1) {
      return remainingFields.iterator().next();

    } else if (remainingFields.contains(DEFAULT_TIME_BUCKET)) {
      return DEFAULT_TIME_BUCKET;
    }

    // Return null if we cannot find the time bucket column
    return null;
  }

  private Expression buildGeneralizedPartitionDelete(
      PartitionSpec spec,
      Set<Map<String, String>> partitionMaps,
      String timeBucketCol,
      Long maxTimeBucket) {

    // Build time bucket conditions
    Expression timeBucketExpr = Expressions.and(
        Expressions.greaterThan(timeBucketCol, 0),
        Expressions.lessThanOrEqual(timeBucketCol, maxTimeBucket));

    // If partition maps are empty (only time bucket column), return just time conditions
    if (partitionMaps.isEmpty() ||
        (partitionMaps.size() == 1 && partitionMaps.iterator().next().isEmpty())) {
      return timeBucketExpr;
    }

    // Build OR expression for all partition maps
    Expression partitionExpr = null;
    for (var partitionMap : partitionMaps) {
      if (partitionMap.isEmpty()) {
        // Skip empty partition maps (they would match everything)
        continue;
      }

      Expression andExpr = null;

      // Build AND expression for all columns in this partition map
      for (Map.Entry<String, String> entry : partitionMap.entrySet()) {
        String columnName = entry.getKey();
        String stringValue = entry.getValue();

        // Cast value to appropriate type based on partition field type
        Object typedValue = castValue(spec, columnName, stringValue);
        Expression colExpr = Expressions.equal(columnName, typedValue);

        if (andExpr == null) {
          andExpr = colExpr;
        } else {
          andExpr = Expressions.and(andExpr, colExpr);
        }
      }

      if (andExpr != null) {
        if (partitionExpr == null) {
          partitionExpr = andExpr;
        } else {
          partitionExpr = Expressions.or(partitionExpr, andExpr);
        }
      }
    }

    // Combine with time bucket conditions
    if (partitionExpr == null) {
      return timeBucketExpr;
    } else {
      return Expressions.and(timeBucketExpr, partitionExpr);
    }
  }

  private Object castValue(PartitionSpec spec, String columnName, String stringValue) {
    if (stringValue == null) {
      return null;
    }

    try {
      // Find the partition field type
      for (var field : spec.fields()) {
        if (field.name().equals(columnName)) {
          var fieldType = spec.schema().findType(field.sourceId());
          return castStringToExpectedColumnType(stringValue, fieldType);
        }
      }

      // If partition column not found, return the string value as fallback
      return stringValue;
    } catch (Exception e) {
      // If casting fails, return the string value as fallback
      return stringValue;
    }
  }

  private Object castStringToExpectedColumnType(String value, Type type) {
    if (value == null) {
      return null;
    }

    try {
      switch (type.typeId()) {
        case STRING:
          return value;
        case INTEGER:
          return Integer.parseInt(value);
        case LONG:
          return Long.parseLong(value);
        case DOUBLE:
          return Double.parseDouble(value);
        case FLOAT:
          return Float.parseFloat(value);
        case BOOLEAN:
          return Boolean.parseBoolean(value);
        case DECIMAL:
          // For decimal types, try to parse as double or return string
          try {
            return Double.parseDouble(value);
          } catch (NumberFormatException e) {
            return value;
          }
        default:
          // For other types, use string value
          return value;
      }
    } catch (NumberFormatException e) {
      // If parsing fails, return the original string value
      return value;
    }
  }
}
