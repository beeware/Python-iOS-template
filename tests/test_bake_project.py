from contextlib import contextmanager
import datetime
import os
import shlex
import subprocess

from cookiecutter.utils import rmtree
import sh
import pytest


@contextmanager
def bake_in_temp_dir(cookies, *args, **kwargs):
    """
    Delete the temporal directory that is created when executing the tests
    :param cookies: pytest_cookies.Cookies, cookie to be baked and its temporal files will be removed
    """
    result = cookies.bake(*args, **kwargs)
    try:
        yield result
    finally:
        rmtree(str(result.project))


def test_app_README(cookies):
    extra_context = {'app_name': 'helloworld'}
    with bake_in_temp_dir(cookies, extra_context=extra_context) as result:
        readme_file = result.project.join('app', 'README')
        readme_text = readme_file.read()
        assert 'helloworld/__main__.py' in readme_text
