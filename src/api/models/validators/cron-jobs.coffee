{ CronJob } = require 'cron'


CronValidator =  {
  validator:  (v) ->
    try
      new CronJob v, () ->
      return true
    catch e
      return false

  message:    '{VALUE} is not a valid cron scheduler'
}


module.exports = {
  CronValidator
}
