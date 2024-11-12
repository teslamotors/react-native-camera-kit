#!/bin/sh

if which swiftlint >/dev/null; then
  swiftlint lint --quiet --autocorrect && swiftlint lint --quiet
else
  echo "warning: SwiftLint not installed, use `brew bundle` to install it"
fi