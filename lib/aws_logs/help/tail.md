## Examples

    aws-logs tail /aws/codebuild/demo --since 60m
    aws-logs tail /aws/codebuild/demo --since "2018-08-08 08:00:00"
    aws-logs tail /aws/codebuild/demo --no-follow
    aws-logs tail /aws/codebuild/demo --format simple
    aws-logs tail /aws/codebuild/demo --filter-pattern Wed

## Examples with Output

Using `--since`

    $ aws-logs tail /aws/codebuild/demo --since 60m --no-follow
    2019-11-27 22:56:05 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220 Wed Nov 27 22:56:04 UTC 2019
    2019-11-27 22:56:16 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220
    2019-11-27 22:56:16 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220 [Container] 2019/11/27 22:56:14 Phase complete: BUILD State: SUCCEEDED
    2019-11-27 22:56:16 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220 [Container] 2019/11/27 22:56:14 Phase context status code:  Message:
    2019-11-27 22:56:16 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220 [Container] 2019/11/27 22:56:14 Entering phase POST_BUILD
    2019-11-27 22:56:16 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220 [Container] 2019/11/27 22:56:14 Phase complete: POST_BUILD State: SUCCEEDED
    2019-11-27 22:56:16 UTC 8cb8b7fd-3662-4120-95bc-efff637c7220 [Container] 2019/11/27 22:56:14 Phase context status code:  Message:
    $

Using `--filter-pattern`.

    $ aws-logs tail /aws/codebuild/demo --filter-pattern Wed --since 60m
    2019-11-27 22:19:41 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:19:37 UTC 2019
    2019-11-27 22:19:49 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:19:47 UTC 2019
    2019-11-27 22:19:59 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:19:57 UTC 2019
    2019-11-27 22:20:09 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:20:07 UTC 2019
    2019-11-27 22:20:19 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:20:17 UTC 2019
    2019-11-27 22:20:29 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:20:27 UTC 2019
    2019-11-27 22:20:39 UTC 0d933e8f-c15b-41af-a5c7-36b54530cb17 Wed Nov 27 22:20:37 UTC 2019

## Since Formats

Since supports these formats:

* s - seconds
* m - minutes
* h - hours
* d - days
* w - weeks

Since does not support combining the formats. IE: 5m30s.

## Filter Pattern

The `--filter-pattern` option is quite powerful as CloudWatch supports a full
[Filter and Pattern Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html).

To match terms with spaces in it, you'll need quotes around it. Otherise, the match will be an OR of the terms. Example:

    aws-logs tail /aws/codebuild/demo --filter-pattern '"Wed Nov 27 23"' --since 3h --no-follow

Here's an example of matching with an exclude pattern using the `-` (minus sign).

    aws-logs tail /aws/codebuild/demo --filter-pattern '"ERROR" - "Exiting"' --since 3h --no-follow
