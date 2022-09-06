# Estimates Automation

For usage instructions refer to the documentation for this project which is contained in the "docs/" folder. 

Documentation has been auto-generated using the lazydocs library, which takes Google-style file/class/function docstrings and turns it into nice Markdown documents. To install lazydocs, in the command line run: 

```pip install lazydocs```

Or install using your method of choice. Since lazydocs expects the docstrings to be properly formatted, a linter should be used before actually using lazydocs to update documentation. The linter I recommend is pydocstyle. To install, in the command line run:

```pip install pydocstyle```

To run on the linter on all files in the directory, go to the folder "QA/2022/Estimates_Automation" and run in the command line: 

```pydocstyle```

Once errors from pydocstyle have been fixed, to actually update documentation, go to the folder "QA/2022/Estimates_Automation" and run in the command line: 

```lazydocs --overview-file="README.md" .```