# Change Log

All notable changes to this project will be documented in this file.
This project *tries* to adhere to [Semantic Versioning](http://semver.org/), even before v1.0.

## [1.0.0] - 2024-04-16
- [#7](https://github.com/tongueroo/aws-logs/pull/7) show if filter, plain default, thread-safe improvements
- change follow to false by default
- custom formatter for puts behavior
- plain format support and fix sliding window
- show_if filter to customize output
- thread-safe logger file option

## [0.5.1] - 2023-11-22
- [#6](https://github.com/tongueroo/aws-logs/pull/6) fix eager load

## [0.5.0] - 2023-11-22
- [#5](https://github.com/tongueroo/aws-logs/pull/5) add options: refresh_rate and wait_exists
- alias File.exists?
- update tail desc

## [0.4.1] - 2022-04-23
- [#4](https://github.com/tongueroo/aws-logs/pull/4) quiet not found option

## [0.4.0] - 2022-01-07
- [#3](https://github.com/tongueroo/aws-logs/pull/3) streams cli command and data method
- fix activesupport require
- streams cli command and data method

## [0.3.4]
- set next_token for large filter_log_events responses

## [0.3.3]
- #2 add overlap to window to account for delayed logs received at the same time

## [0.3.2]
- #1 clean up end_loop_signal logic

## [0.3.1]
- fix --no-follow option

## [0.3.0]
- display final logs upon stop_follow!

## [0.2.0]
- add stop_follow! method
- friendly error message when log not found
- improve `@follow` default, `@log_group_name` and stdout sync true by default

## [0.1.0]
- Initial release.
