@skip
Feature: Exact Phrase Matching
    Background:
        Given I have a "public/index.html" file with the body:
            """
            <p data-count>Nothing</p>
            <p data-result>Nothing</p>
            """

    Scenario: Searching in quotes will return pages with exact matches
        Given I have a "public/cat/index.html" file with the body:
            """
            <h1>Happy post about cats</h1>
            """
        Given I have a "public/dog/index.html" file with the body:
            """
            <h1>A post about how cats do not like dogs</h1>
            """
        When I run my program
        Then I should see "Running Pagefind" in stdout
        When I serve the "public" directory
        When I load "/"
        When I evaluate:
            """
            async function() {
                let pagefind = await import("/_pagefind/pagefind.js");

                let results = await pagefind.search(`"about cats"`);

                document.querySelector('[data-count]').innerText = `${results.length} result(s)`;
                let data = await results[0].data();
                document.querySelector('[data-result]').innerText = data.url;
            }
            """
        Then There should be no logs
        Then The selector "[data-count]" should contain "1 result(s)"
        Then The selector "[data-result]" should contain "/cat/"

    Scenario: Exact matches will be discouraged across element boundaries
        Given I have a "public/catone/index.html" file with the body:
            """
            <p>Happy post</p>
            <p>about cats</p>
            """
        Given I have a "public/cattwo/index.html" file with the body:
            """
            <p>Happy post about cats</p>
            """
        When I run my program
        Then I should see "Running Pagefind" in stdout
        When I serve the "public" directory
        When I load "/"
        When I evaluate:
            """
            async function() {
                let pagefind = await import("/_pagefind/pagefind.js");

                let results = await pagefind.search(`"post about"`);

                document.querySelector('[data-count]').innerText = `${results.length} result(s)`;
                let data = await results[0].data();
                document.querySelector('[data-result]').innerText = data.url;
            }
            """
        Then There should be no logs
        Then The selector "[data-count]" should contain "1 result(s)"
        Then The selector "[data-result]" should contain "/cattwo/"

    Scenario: Exact matches will match across stop words
        Given I have a "public/cat/index.html" file with the body:
            """
            <h1>Happy post about the cats</h1>
            """
        # This file will _also_ match, due to our stop word culling
        Given I have a "public/dog/index.html" file with the body:
            """
            <h1>A post not about happy cats</h1>
            """
        When I run my program
        Then I should see "Running Pagefind" in stdout
        When I serve the "public" directory
        When I load "/"
        When I evaluate:
            """
            async function() {
                let pagefind = await import("/_pagefind/pagefind.js");

                let search = await pagefind.search(`"about the cats"`);

                document.querySelector('[data-count]').innerText = `${search.results.length} result(s)`;
                let data = await Promise.all(search.results.map(result => result.data()));
                document.querySelector('[data-result]').innerText = data.map(d => d.url).join(', ');
            }
            """
        Then There should be no logs
        Then The selector "[data-count]" should contain "2 result(s)"
        Then The selector "[data-result]" should contain "/cat/, /dog/"

