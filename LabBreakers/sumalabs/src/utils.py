import os
import sys
import subprocess
import time
import yaml
from alive_progress import alive_bar
import paramiko
from paramiko import SSHClient, AutoAddPolicy
import re
import os
from contextlib import contextmanager

silencer = ' > /dev/null 2>&1'
bar_theme = 'classic'
client_password = "linux"

# query_yes_no function - borrowed from here: https://code.activestate.com/recipes/577058/ or https://stackoverflow.com/questions/3041986/apt-command-line-interface-like-yes-no-input
def query_yes_no(question, default="yes"):
    """
    Ask a yes/no question via raw_input() and return their answer.
    Parameters
    ----------
    question : string
        is a string that is presented to the user.
    default : string
        is the presumed answer if the user just hits <Enter>.
        It must be "yes" (the default), "no" or None (meaning
        an answer is required of the user).
    Returns
    ------- 
    string:
        The "answer" return value is True for "yes" or False for "no".
    """
    valid = {"yes": True, "y": True, "ye": True,
             "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)
    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == '':
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write("Please respond with 'yes' or 'no' "
                             "(or 'y' or 'n').\n")
            
def create_alive_bar(bar_title, tasks):
    total_items = len(tasks)
    with alive_bar(total_items, theme=bar_theme, title=bar_title) as bar:
        for task in tasks:
            try:
                task()
                advance_progress(bar)
            except Exception as e:
                print(f"Error occurred while executing task: {task.__name__} - {str(e)}")
                # Optionally, break the loop if you want to stop processing tasks on failure
                # break

def advance_progress(bar):
    bar()
    time.sleep(1)

def set_working_dir(work_dir):
    try:
        os.chdir(work_dir)
    except FileNotFoundError:
        print("Directory: {0} does not exist".format(work_dir))
    except NotADirectoryError:
        print("{0} is not a directory".format(work_dir))
    except PermissionError:
        print("You do not have permissions to change to {0}".format(work_dir))

def add_line_to_file(line, file_path, debug=False):
    """
    Add a line to the specified file if it doesn't already exist.
    Parameters
    ----------
    file_path : string
        The path of the file where the line should be added.
    line : string
        The line to be added to the file.
    """
    with open(file_path, 'a+') as file:
        lines = file.readlines()
        if line + "\n" not in lines:
            if debug:
                print(f"Adding line to {file_path}: {line}")
            if file.tell() > 0 and not file.read()[-1:] == '\n':
                file.write("\n")
            file.write(f"{line}\n")
        else:
            if debug:
                print(f"Line already exists in {file_path}: {line}")

def load_yaml_config(file_path):
    with open(file_path, 'r') as yaml_file:
        try:
            return yaml.safe_load(yaml_file)
        except yaml.YAMLError as e:
            print(f"Error loading YAML file: {e}")
            return None  

def remove_line_from_file(partial_line, file_path, debug=False):
    if not os.path.exists(file_path):
        if debug:
            print(f"{file_path} does not exist.")
        return

    with open(file_path, 'r') as file:
        lines = file.readlines()

    with open(file_path, 'w') as file:
        for line in lines:
            if partial_line not in line:
                file.write(line)
            elif debug:
                print(f"Removing line from {file_path}: {line.strip()}") 

def load_yaml_config(config_path):
    try:
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
        return config
    except Exception as e:
        print(f"Error loading YAML configuration: {e}")
        return None   

def ssh_connect(host, username, password=None, command='', debug=False):
    client = SSHClient()
    client.set_missing_host_key_policy(AutoAddPolicy()) 
    try:
        client.connect(host, username=username, password=password, look_for_keys=True)
        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode('utf-8')
        if debug:
            print(f"on {host}: {output}")
        client.close()
        return output
    except Exception as e:
        if debug:
            print(f"on {host}: {str(e)}")
        client.close()
        return None 
    
def modify_file_using_regex(pattern, replacement, file_path, debug=False):
    if debug:
        print(f"Modifying {file_path}: replacing '{pattern}' with '{replacement}'")
    with open(file_path, 'r') as file:
        content = file.read()
    content = re.sub(pattern, replacement, content)
    with open(file_path, 'w') as file:
        file.write(content)

@contextmanager
def shutup():
    old_stdout = os.dup(1)
    old_stderr = os.dup(2)
    os.dup2(os.open(os.devnull, os.O_WRONLY), 1)
    os.dup2(os.open(os.devnull, os.O_WRONLY), 2)
    try:
        yield
    finally:
        os.dup2(old_stdout, 1)
        os.dup2(old_stderr, 2)
        os.close(old_stdout)
        os.close(old_stderr)
     