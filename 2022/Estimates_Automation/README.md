To generate Markdown documentation, you need pdoc3 (NOT pdoc). To install pdoc3, do "pip install pydoc3".

To actually generate the documentation, in the command line, in the folder "QA/2022/Estimates_Automation", run "pdoc --output-dir docs -c sort_identifiers=False --force ."

TODO (Eric): Figure out why ast is preventing command line option "-c docformat=google" from going through. May need to actually use Sphinx/Napolean if pdoc3 refuses to work