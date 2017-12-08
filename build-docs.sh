#!/bin/bash

jazzy \
    --module DeckTransition \
    --swift-version 4.0 \
    --author Harshil Shah \
    --author_url https://twitter.com/HarshilShah1910 \
    --copyright "Copyright © 2017 Harshil Shah. Available under the MIT License." \
    --github_url https://github.com/HarshilShah/DeckTransition \
    --github-file-prefix https://github.com/HarshilShah/DeckTransition/tree/master \
    --root-url https://harshilshah.github.io/DeckTransition \
    --documentation "Guides/*.md" \
    --output docs/ \
