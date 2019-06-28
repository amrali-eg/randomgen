# -*- coding: utf-8 -*-
#
# Configuration file for the Sphinx documentation builder.
#
# This file does only contain a selection of the most common options. For a
# full list see the documentation:
# http://www.sphinx-doc.org/en/stable/config

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))
import guzzle_sphinx_theme
import randomgen

# -- Project information -----------------------------------------------------

project = 'RandomGen'
copyright = '2018, Kevin Sheppard'
author = 'Kevin Sheppard'

# The short X.Y version.

version = randomgen.__version__
if '+' in version:
    version = version.split('+')
    version = ''.join((version[0], ' (+', version[1].split('.')[0], ')'))
# The full version, including alpha/beta/rc tags.
release = randomgen.__version__

# -- General configuration ---------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#
# needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx.ext.napoleon',
    'sphinx.ext.autodoc',
    'sphinx.ext.extlinks',
    'sphinx.ext.todo',
    'sphinx.ext.doctest',
    'sphinx.ext.intersphinx',
    'sphinx.ext.autosummary',
    'sphinx.ext.mathjax',
    'sphinx.ext.githubpages',
    'IPython.sphinxext.ipython_console_highlighting',
    'IPython.sphinxext.ipython_directive'
]

try:
    import sphinxcontrib.spelling  # noqa: F401
except ImportError as err:  # noqa: F841
    pass
else:
    extensions.append('sphinxcontrib.spelling')

spelling_word_list_filename = ['spelling_wordlist.txt', 'names_wordlist.txt']
spelling_ignore_pypi_package_names = True


# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The master toctree document.
master_doc = 'index'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
language = None

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path .
exclude_patterns = []

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
# html_theme = 'alabaster'
# html_theme = 'sphinx_rtd_theme'
# html_theme_path = ["_themes", ]
# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#
# html_theme_options = {}

html_translator_class = 'guzzle_sphinx_theme.HTMLTranslator'
html_theme_path = guzzle_sphinx_theme.html_theme_path()
html_theme = 'guzzle_sphinx_theme'

# Register the theme as an extension to generate a sitemap.xml
extensions.append("guzzle_sphinx_theme")

# Guzzle theme options (see theme.conf for more information)
html_theme_options = {
    # Set the name of the project to appear in the sidebar
    "project_nav_name": project + u" " + version,
}

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# Custom sidebar templates, must be a dictionary that maps document names
# to template names.
#
# The default sidebars (for documents that don't match any pattern) are
# defined by theme itself.  Builtin themes are using these templates by
# default: ``['localtoc.html', 'relations.html', 'sourcelink.html',
# 'searchbox.html']``.
#
# html_sidebars = {}
html_sidebars = {
    '**': ['logo-text.html', 'globaltoc.html', 'searchbox.html']
}

# If false, no module index is generated.
html_domain_indices = True

# -- Options for HTMLHelp output ---------------------------------------------

# Output file base name for HTML help builder.
htmlhelp_basename = 'RandomGendoc'


# -- Options for LaTeX output ------------------------------------------------

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    #
    # 'papersize': 'letterpaper',

    # The font size ('10pt', '11pt' or '12pt').
    #
    # 'pointsize': '10pt',

    # Additional stuff for the LaTeX preamble.
    #
    # 'preamble': '',

    # Latex figure (float) alignment
    #
    # 'figure_align': 'htbp',
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
    (master_doc, 'RandomGen.tex', 'RandomGen Documentation',
     'Kevin Sheppard', 'manual'),
]


# -- Options for manual page output ------------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc, 'RandomGen', 'RandomGen Documentation',
     [author], 1)
]


# -- Options for Texinfo output ----------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (master_doc, 'RandomGen', 'RandomGen Documentation',
     author, 'RandomGen', 'Alternative random number generators for Python.',
     'Miscellaneous'),
]


# -- Extension configuration -------------------------------------------------

# -- Options for intersphinx extension ---------------------------------------

# Example configuration for intersphinx: refer to the Python standard library.
intersphinx_mapping = {
    'statsmodels': ('http://www.statsmodels.org/dev/', None),
    'matplotlib': ('https://matplotlib.org', None),
    'scipy': ('https://docs.scipy.org/doc/scipy/reference/', None),
    'python': ('https://docs.python.org/3', None),
    'numpy': ('https://docs.scipy.org/doc/numpy', None),
    'np': ('https://docs.scipy.org/doc/numpy', None),
    'pandas': ('https://pandas.pydata.org/pandas-docs/stable/', None),
    'pd': ('https://pandas.pydata.org/pandas-docs/stable/', None),
}

autosummary_generate = True

doctest_global_setup = """
import numpy as np

import randomgen

import matplotlib.pyplot

def show(*args, **kwargs):
    return

matplotlib.pyplot.show = show
"""
