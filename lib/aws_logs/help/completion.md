## Examples

    aws-logs completion

Prints words for TAB auto-completion.

    aws-logs completion
    aws-logs completion hello
    aws-logs completion hello name

To enable, TAB auto-completion add the following to your profile:

    eval $(aws-logs completion_script)

Auto-completion example usage:

    aws-logs [TAB]
    aws-logs hello [TAB]
    aws-logs hello name [TAB]
    aws-logs hello name --[TAB]
