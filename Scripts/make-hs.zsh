#!/bin/zsh

additions=(applescript coffeescript ada brainfuck delphi clojure fortran arduino vbscript lisp erlang elixir protobuf armasm latex)

cd $GIT/highlight.js
if node tools/build.js -t browser :common ${additions} ; then
    cp build/highlight.min.js $GIT/HighlighterSwift/Sources/Assets/highlight.min.js
else
    echo "Build error"
fi