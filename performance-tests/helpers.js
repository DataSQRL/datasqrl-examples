const dayjs = require('dayjs');

module.exports = {
  getDateRange: function (userContext, events, done) {
    const now = dayjs();

    userContext.vars.toTime = now.format('YYYY-MM-DDT00:00:00-00:00');

    const monthsAgo = Math.floor(Math.random() * 6) + 1;
    userContext.vars.fromTime = now.subtract(monthsAgo, 'month').format('YYYY-MM-DDT00:00:00-00:00');

    return done();
  },

  getCardType: function (userContext, events, done) {
    const cardTypes = ['travel', 'sports', 'business', 'family'];
    const randomIndex = Math.floor(Math.random() * cardTypes.length);
    userContext.vars.cardType = cardTypes[randomIndex];
    return done();
  },
};
