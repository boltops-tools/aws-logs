# aws-logs

[![Gem Version](https://badge.fury.io/rb/aws-logs.png)](http://badge.fury.io/rb/aws-logs)

[![BoltOps Badge](https://img.boltops.com/boltops/badges/boltops-badge.png)](https://www.boltops.com)

Tail AWS CloudWatch Logs.

## Usage

    aws-logs tail LOG_GROUP

## Examples

Here's a couple of examples where `LOG_GROUP=/aws/codebuild/demo`:

    aws-logs tail /aws/codebuild/demo --since 60m
    aws-logs tail /aws/codebuild/demo --since "2018-08-08 08:00:00"
    aws-logs tail /aws/codebuild/demo --no-follow
    aws-logs tail /aws/codebuild/demo --format simple
    aws-logs tail /aws/codebuild/demo --filter-pattern Wed

* By default, the tail command **will** follow the logs.  To not follow use the `--no-follow` option.
* The default format is detailed. The detailed format includes the log stream name.

## Installation

Install with:

    gem install aws-logs

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am "Add some feature"`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
