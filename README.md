# GitLab_CI-CD_Selenium-Grid

This project serves to illustrate the automated provisioning of the Selenium Grid. Shell runners from GitLab can be converted to Selenium components. A distinction can be made between Selenium Hub and Selenium Nodes. To make this possible for different operating systems, scripts were created for each operating system.

The following variables can be changed in the pipeline for the configuration of the runners:

``` yaml
variables:
  SELENIUM_HUB_URL: "http://localhost:4444/" # without this parameter, it is started as a Selenium-Hub
  SELENIUM_OS: "windows" # linux, macos, or windows
```
