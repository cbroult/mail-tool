* Add a fully integrated stage in the CI pipeline/rake task where some of the feature scenarios are testing
  using an actual IMAP server (i.e., not mocked). The selected scenarios should be representative of the features, so
  that we have an increased confidence in the implementation (i.e., reduce the risk of discovering bugs after
  the release). For that look into IMAP servers using either / or . as a delimiter.
* Inspect the code based to detect cases where the coding style is not followed. Act accordingly.
* Implement code coverage testing
* Lint code for style consistency add that to the CI pipeline/rake task
* Implement automated documentation generation
* Implement automated testing for edge cases
* Implement automated testing for performance
* Implement automated testing for security vulnerabilities
* Implement automated testing for accessibility
* Implement automated testing for usability 
