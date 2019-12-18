# Change Log

All notable changes to this project will be documented in this file.
This project *tries* to adhere to [Semantic Versioning](http://semver.org/), even before v1.0.

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
