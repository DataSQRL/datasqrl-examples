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
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import javax.annotation.Nullable;
import org.apache.flink.table.annotation.DataTypeHint;
import org.apache.flink.table.functions.ScalarFunction;
import org.apache.iceberg.PartitionField;
import org.apache.iceberg.PartitionSpec;
import org.apache.iceberg.Table;
import org.apache.iceberg.expressions.Expression;
import org.apache.iceberg.expressions.Expressions;
import org.apache.iceberg.types.Type;
import org.apache.iceberg.types.Types;

@AutoService(ScalarFunction.class)
public class delete_duplicated_data extends ScalarFunction {

  /**
   * Deletes duplicated data from an Iceberg table based on partition specifications and time bucket constraints.
   * 
   * @param warehouse The warehouse path or URI for the catalog
   * @param catalogType The type of catalog (optional, e.g., "hadoop", "hive")
   * @param catalogName The name of the catalog
   * @param databaseName The database/schema name (optional)
   * @param tableName The name of the table to delete from
   * @param maxTimeBucket The maximum time bucket value (inclusive) for records to delete
   * @param partitionSet Set of partition specifications where each map contains column name -> value mappings.
   *                     Maps can be empty for tables partitioned only by time bucket column.
   *                     All maps must have the same keyset (same partition columns).
   * @return true if deletion was successful, false if invalid parameters provided
   */
  public boolean eval(
      String warehouse,
      @Nullable String catalogType,
      String catalogName,
      @Nullable String databaseName,
      String tableName,
      Long maxTimeBucket,
      @DataTypeHint("MULTISET<MAP<STRING, STRING>>") Map<Map<String, String>, Integer> partitionSet) {

    return deleteDeduplicatedData(
        warehouse, catalogType, catalogName, databaseName, tableName, maxTimeBucket, partitionSet);
  }

  private boolean deleteDeduplicatedData(
      String warehouse,
      @Nullable String catalogType,
      String catalogName,
      @Nullable String databaseName,
      String tableName,
      Long maxTimeBucket,
      Map<Map<String, String>, Integer> partitionSet) {

    if (warehouse == null
        || catalogName == null
        || tableName == null
        || maxTimeBucket == null
        || partitionSet == null
        || partitionSet.isEmpty()) {
      return false;
    }

    // Verify all maps have the same keyset
    Set<String> partitionColumns = null;
    for (Map<String, String> partitionMap : partitionSet.keySet()) {
      if (partitionColumns == null) {
        partitionColumns = new HashSet<>(partitionMap.keySet());
      } else if (!partitionColumns.equals(partitionMap.keySet())) {
        // Return false instead of throwing exception to avoid crashing Flink job
        return false;
      }
    }

    if (partitionColumns == null) {
      partitionColumns = new HashSet<>(); // Handle case with no partition columns
    }

    try {
      Function<Table, Void> delFn =
          table -> {
            // Get partition spec and find time bucket column
            PartitionSpec spec = table.spec();
            String timeBucketCol = findTimeBucketColumn(spec, partitionColumns);
            
            // If no time bucket column found, cannot proceed
            if (timeBucketCol == null) {
              return null;
            }

            // Build delete expression
            Expression delExpr = buildGeneralizedPartitionDelete(
                spec, partitionSet.keySet(), timeBucketCol, maxTimeBucket);

            // Execute delete
            var delFiles = table.newDelete().deleteFromRowFilter(delExpr);
            delFiles.commit();

            return null;
          };

      CatalogUtils.executeInCatalog(
          warehouse, catalogType, catalogName, databaseName, tableName, delFn);

      return true;
    } catch (Exception e) {
      // Return false instead of letting exception propagate
      return false;
    }
  }

  private String findTimeBucketColumn(PartitionSpec spec, Set<String> partitionColumns) {
    // Handle unpartitioned tables
    if (spec.isUnpartitioned()) {
      return null;
    }
    
    Set<String> allPartitionFields = new HashSet<>();
    for (PartitionField field : spec.fields()) {
      allPartitionFields.add(field.name());
    }

    // Find the time bucket column by removing known partition columns
    Set<String> remainingFields = new HashSet<>(allPartitionFields);
    remainingFields.removeAll(partitionColumns);

    // Return null if we don't find exactly one time bucket column
    if (remainingFields.size() != 1) {
      return null;
    }

    return remainingFields.iterator().next();
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
    for (Map<String, String> partitionMap : partitionMaps) {
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
      for (PartitionField field : spec.fields()) {
        if (field.name().equals(columnName)) {
          Type fieldType = spec.schema().findType(field.sourceId());
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
