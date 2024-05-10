#!/usr/bin/env awk
#
# Replace tag in YAML file based on matching repository.
# Requires passing `repository` and `tag` as an argument, e.g.
#
#   awk \
#     -v repository=example.com/repo/repo \
#     -v tag=new-tag \
#     -f update-repo-tag.awk file.yaml > file.yaml.new
#
# Works with both One True AWK (nawk) and GNU awk (gawk).
{
    if (repository != "" && tag != "") {
        if ($0 ~ "^.*repository: ['\"]?" repository "['\"]?$") {
            matched = 1
        } else if (match($0, "^.*tag:") && matched == 1) {
            $0 = substr($0, RSTART, RLENGTH) " \"" tag "\""
            matched = 0
        }
    }
    print $0
}
