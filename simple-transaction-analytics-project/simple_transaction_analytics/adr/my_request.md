# Request: transaction analytics and spending insights

## Context

Our teams cannot see how a customer spends. A service agent opens a raw list of transactions and
reads it line by line while the customer waits on the call. The product team exports a file and
counts in a spreadsheet. Two teams answer the same question with different numbers.

We already have the data. The transactions team gives us transactions with a category and a merchant
name. We only need to build the numbers on top of them.

These numbers are for our own staff. Our teams look at last week and at last month. They do not look
at the last minute. A job that runs every night is enough, and it also keeps the cost low.

## What we want to build

We want a batch job that runs every night. It reads transactions, computes insights and writes them
to Iceberg.

The job must work in an incremental way. It must not read the whole history every night. That is
slow and expensive, and it gets worse as we grow. Each run should compute the results for a short
window of recent days again, and it should keep the older results as they are.

Please choose the length of that window and explain your choice. Transactions need a few days to
settle. They get posted, they get a category, and sometimes they get reversed. The window must cover
that time.

The run date is important for us. By default it should be the last full day. We also want to set it
by hand, because a night can fail and we then need to run it again. A run with the same date and the
same input must give the same result.

## What counts as spending

Deposit accounts only: checking and savings. Debit card purchases count, they sit on the deposit account. Credit cards are not considered.

All currencies count. Amounts convert to USD at the rate of the transaction's business date. We need to build that rate table ourselves.

## The insights

Our service and product teams asked for the insights below. Every insight is about one customer.

- The spending per category for each month. Next to it, we want the normal spending of that customer
  in that category. The team wants a flag that says the customer spent much more than usual. Please define
  what "much more" means. Use a percentage and also a minimum amount. Please also say how many months
  of history we need before we can talk about normal spending.
- The merchants where the customer spent the most money in a month.
- The recurring payments of the customer. We want the cost per month for each one. Different payments
  repeat at different speeds, so please turn every one of them into a monthly cost. We also want the
  total cost per month. Finally, we want to see which recurring payment became more expensive. This
  is the insight that the product team wants most.
- Purchases that are unusually large for that customer. Please compare them with the recent behaviour
  of the same customer, and not with one fixed amount.
- The money in, the money out, what is left, and how much of the income is left, for each month.

The current month is not finished. Please show it as the month so far.

Please write clear rules for the cases below. A transaction can be pending and can become posted
later. A transaction can be reversed or returned. A refund can arrive. A customer can move money
between their own accounts, and that is not real spending, but the data does not mark it.

## The screens for our staff

We also want a small web application for our own teams. A user signs in with a staff account (use JWT, Any signed-in staff user can open any customer). 
The application reads all data through our own API. It must not show a number that the API does not give. 

We need five screens.

- A customer search. A user types a customer id and opens that customer. Every other screen then
  shows the customer that the user opened.
- A month overview. It shows the money in, the money out, what is left and the share of the income
  that is left. The user picks a month. The user can also pick one account of that customer. The same
  screen shows the spending per day of the chosen month as a chart.
- A category screen. It shows the spending per category for the chosen month. Next to each category
  it shows the normal value and the flag when the customer spent much more than usual. The user can
  open a category and see the merchants behind it.
- A recurring payments screen. It lists the recurring payments with the cost per month. It shows the
  total cost per month. It marks the payments that became more expensive.
- A large purchases screen. It lists the unusually large purchases with the date, the merchant and
  the amount.

The current month is not finished, so the overview shows it as the month so far and without the
comparison. The account list only holds the accounts of the open customer.

## Data quality and monitoring

The product team asks us every week if the numbers are correct. Please answer that question inside
the pipeline.

- For each run, keep four values. Keep the run date. Keep the days that the job computed again. Keep
  the number of transactions that it processed. Keep the number of transactions that arrived too late
  for the window. The last number tells us if our window is long enough.
- Report the share of spending without a category for each day. The categories come from another
  team. If their work breaks, our insights become useless, and we want to see that at once.

## Data and environments

All source data comes from the shared data catalog module.

In the test environment we read local files and we use a fixed run date, so the test results stay
stable. In production the job runs Flink in batch mode every night. It reads the catalog tables and
writes Iceberg. DuckDB reads those tables and Vert.x serves them.

