Philosopher is a short Ruby program that lets you see if you can get "Back to Philosophy" from
any other wiki page. If you start at (almost) any regular Wikipedia encyclopedia entry, you'll
eventually wind up on the Philosophy page, following these rules:

* Visit the first non-parenthesized, non-italicized link
* Ignore external links or links to the current page
* Stop when you reach "Philosophy"
* Stop when you reach a page with no links
* Stop when you reach a page that does not exist
* Stop when a loop occurs

This particular implementation ignores the last rule, because that's not very interesting.
Instead, we pick the next non-visited link on the page directly before the start of a
detected cycle. For example, if we visit [A, B, C, D], and we're about to visit `C` again
on `D`, starting a cycle, then we need to backtrack. We will instead pick the _second_
link on `B`, instead of the first valid link on `B`.

Usage:

    ruby ./philosopher.rb "Ruby"         # to start at the article named "Ruby"
    ruby ./philosopher.rb "Programming"  # to start at the article named "Programming"
    ruby ./philosopher.rb                # to start at a randomly selected article
