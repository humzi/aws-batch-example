
# Welcome to your CDK Python project!

This is a blank project for CDK development with Python.

The `cdk.json` file tells the CDK Toolkit how to execute your app.

This project is set up like a standard Python project.  The initialization
process also creates a virtualenv within this project, stored under the `.venv`
directory.  To create the virtualenv it assumes that there is a `python3`
(or `python` for Windows) executable in your path with access to the `venv`
package. If for any reason the automatic creation of the virtualenv fails,
you can create the virtualenv manually.

To manually create a virtualenv on MacOS and Linux:

```
$ python3 -m venv .venv
```

After the init process completes and the virtualenv is created, you can use the following
step to activate your virtualenv.

```
$ source .venv/bin/activate
```

If you are a Windows platform, you would activate the virtualenv like this:

```
% .venv\Scripts\activate.bat
```

Once the virtualenv is activated, you can install the required dependencies.

```
$ pip install -r requirements.txt
```

At this point you can now synthesize the CloudFormation template for this code.

```
$ cdk synth
```

To add additional dependencies, for example other CDK libraries, just add
them to your `setup.py` file and rerun the `pip install -r requirements.txt`
command.

## Useful commands

 * `cdk ls`          list all stacks in the app
 * `cdk synth`       emits the synthesized CloudFormation template
 * `cdk deploy`      deploy this stack to your default AWS account/region
 * `cdk diff`        compare deployed stack with current state
 * `cdk docs`        open CDK documentation

Enjoy!


# Setting up automatic code formating using flake8

Using pre-commit hooks (recommended):

First, install pre-commit:

pip install pre-commit

Copy

Insert at cursor
bash
Create a .pre-commit-config.yaml file in your project root:

repos:
-   repo: https://github.com/pycqa/flake8
    rev: 7.0.0  # Use the latest version
    hooks:
    -   id: flake8

Then install the pre-commit hooks:

pre-commit install

C
Configure flake8 settings: Create a .flake8 file in your project root:

[flake8]
max-line-length = 88
extend-ignore = E203
exclude = .git,__pycache__,build,dist
max-complexity = 10

For automatic fixing of some flake8 issues, you can use additional tools like autopep8:

pip install autopep8

To automatically fix code:

autopep8 --in-place --aggressive --aggressive *.py

VS Code: Install the Python extension and enable flake8 linting

PyCharm: Enable flake8 inspection in settings

Looking at your open app.py file, you might want to run:

autopep8 --in-place app.py

This will automatically fix common style issues like indentation and line length problems.

Remember that not all flake8 issues can be fixed automatically - some will require manual intervention. The pre-commit hook approach is particularly useful as it prevents commits that don't meet the flake8 standards, helping maintain code quality.

