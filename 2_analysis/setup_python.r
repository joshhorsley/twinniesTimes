library(reticulate)
# install python if needed install_python(version = "3.14:latest")
virtualenv_create("./venv")
py_install("mailchimp-marketing", envname = "./venv/")

py_require(packages = "mailchimp-marketing",
           python_version = ">=3.13.7")
