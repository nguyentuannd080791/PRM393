module.exports = fn => async (req, res, next) => {
  try { await fn(req, res); } catch (error) { next(error); }
};
