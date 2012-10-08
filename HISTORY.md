# 0.5.1
- Cleanup the output and clean up some code

# 0.5.0
- Support for >= guard-1.1.0

# 0.4.0
- Updated output support to handle the multiple output files introduced with brakeman 1.5.3

# 0.3.0
- The output of guard-brakeman now uses the same code as the regular brakeman reports and uses the same options (thanks DarkTatka for the input)

# 0.2.0
- Moar better notifications
- 'chatty' config option allows you to enter "fix mode" where ALL brakeman activity is growl'd.  Off by default, which means you are only alerted on NEW or FIXED findings
- Add :min_confidence setting to ignore results under a certain threshold

# 0.1.8
- More consistent output
- Consolidate growls into a single message
- Add run_on_start option

# 0.1.7
- Ability to turn off notifications
- Test backfill

# 0.1.6
- Added notificaiton (growl) support
- Use UI:: methods to print messages to console (report still uses puts)
