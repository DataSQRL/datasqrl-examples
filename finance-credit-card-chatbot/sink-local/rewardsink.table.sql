CREATE TABLE CustomerRewards (
     PRIMARY KEY (`customerId`) NOT ENFORCED
) WITH (
      'connector' = 'print',
      'print-identifier' = 'Customer-Rewards'
      );