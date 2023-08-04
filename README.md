# ngrok-mtls-edge
An example Bash script that configures a MTLS Edge and Registers a Domain on ngrok

The example above configures the following:
* Create an ngrok Edge
* Registers a domain, (yourlabel.ngrok.app)
* Configures a Certificate Authority based on supplied files
* Registers a Certificate Authority
* Creates a MTLS Connection

Hopefully, this will be a usable reference anyone can use to create edges in ngrok.

## Running this script

An ngrok API Key is required to run this script, and configured in your Environment.

This script also requires your Certificates to be named and configured based on the
example in this repository.

https://github.com/ngrok-patrick/Jenky-CA-Script

The script is run like this:
`./certEdge.sh your_label`



