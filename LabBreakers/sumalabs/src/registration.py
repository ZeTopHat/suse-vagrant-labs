import os
import utils
import time
import socket
import subprocess
import yaml
import sys
import paramiko
import re
import random

def lab1(debug=False):
    lab_name = "registration lab1"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"
        client2break = "client1" 

        def task0():
            time.sleep(1)
            pass

        def task1():
            ssh_output = utils.ssh_connect(client2break, 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass

        def task2():
            command = 'rm -rf /etc/salt /etc/venv-salt-minion'
            result = utils.ssh_connect(client2break, 'root', utils.client_password, command, debug)
            if debug:
                print(f"Cleaning potential salt files on client1.")
                print(result)
            pass

        def task3():
            command = "mkdir -p /etc/salt /etc/venv-salt-minion/"
            result = utils.ssh_connect(client2break, 'root', utils.client_password, command, debug)
            if debug:
                print(f"Creating salt client directories if needed on client1.")
                print(result)
            pass

        def task4():
            command = "chattr +i /etc/venv-salt-minion"
            result = utils.ssh_connect(client2break, 'root', utils.client_password, command, debug)
            if debug:
                print(f"Changing directory attributes for /etc/venv-salt-minion on client1.")
                print(result)
            pass    

        def task5():
            command = "chattr +i /etc/salt"
            result = utils.ssh_connect(client2break, 'root', utils.client_password, command, debug)
            if debug:
                print(f"Changing directory attributes for /etc/salt on client1.")
                print(result)
            pass

        tasks = [task0, task1, task2, task3, task4, task5]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Register client1 to SUSE Manager.")
        print("- Verify that the system is accessible via the WebUI Systems page.")
        print("- Discover any issues, and fix them.")
    else:
        print(" ")          


def lab2(debug=False):
    lab_name = "registration lab2"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"
        client2break = "client2" 

        def task0():
            time.sleep(1)
            pass

        def task1():
            ssh_output = utils.ssh_connect(client2break, 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass


        def task2():
            command = f'zypper in -y salt-minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 


        def task3():
            command = f'cp /etc/salt/minion /tmp/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f'Copying /etc/salt/minion on the host to /tmp/minion for file manipulation.')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task4():
            command = r"sed -i '/^#master_port: 4506/a master_port: 45506' /tmp/minion"
            result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f'Modifying the /tmp/minion file.')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task5():
            command = "mkdir -p /etc/salt /etc/venv-salt-minion/"
            result = utils.ssh_connect(client2break, 'root', utils.client_password, command, debug)
            if debug:
                print(f"Creating salt client directories if needed on client1.")
                print(result)
            pass    

        def task6():
            command = f'rsync -r /tmp/minion {client2break}:/etc/salt/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Moving /tmp/minion file to client2:/etc/salt/minion")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task7():
            command = f'rsync -r /tmp/minion {client2break}:/etc/venv-salt-minion/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Moving /tmp/minion file to client2:/etc/venv-salt-minion/minion")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task8():
            command = f'rm -rf /tmp/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Cleaning up local /tmp/minion file.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass           

        tasks = [task0, task1, task2, task3, task4, task5, task6, task7, task8]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Register client1 to SUSE Manager.")
        print("- Verify that the system is accessible via the WebUI Systems page.")
        print("- Discover any issues, and fix them.")
    else:
        print(" ")   


def lab3(debug=False):
    lab_name = "registration lab3"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"
        client2break = "client3"

        def task0():
            time.sleep(1)
            pass

        def task1():
            ssh_output = utils.ssh_connect(client2break, 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass


        def task2():
            command = f'cp /etc/sysconfig/proxy /tmp/proxy'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Copying /etc/sysconfig/proxy to /tmp/proxy for file manipulation.')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 

        def task3():
            pattern = r'PROXY_ENABLED=.*'
            replacement = 'PROXY_ENABLED="yes"'
            utils.modify_file_using_regex(pattern, replacement, '/tmp/proxy', debug)
            if debug:
                print('Enabling proxy in /tmp/proxy file.')
            pass        

        def task4():
            pattern = r'HTTPS_PROXY=.*'
            replacement = 'HTTPS_PROXY="192.168.0.1"'
            utils.modify_file_using_regex(pattern, replacement, '/tmp/proxy', debug)
            if debug:
                print('Setting HTTPS_PROXY in /tmp/proxy file.')
            pass

        def task5():
            line = f'export https_proxy="http://192.168.0.1"'
            utils.add_line_to_file(line, "/tmp/bashrc", debug)
            if debug: 
                print(f"Adding line to /tmp/bashrc: {line}")
            pass                

        def task6():
            command = f'scp /tmp/proxy {client2break}:/etc/sysconfig/proxy'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Copying /tmp/proxy to client3:/etc/sysconfig/proxy')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task7():
            command = f'scp /tmp/bashrc {client2break}:/root/.bashrc'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Copying /tmp/bashrc to client3:/root/.bashrc')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task8():
            command = f'ssh {client2break} reboot'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Rebooting client3')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task9():
            command = f'rm /tmp/proxy /tmp/bashrc'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Cleaning up local files: /tmp/proxy /tmp/.bashrc')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task10():
            print('waiting 5 seconds')
            time.sleep(5)
            pass
    
        def task11():
            print('waiting 5 seconds')
            time.sleep(5)
            pass
    
        def task12():
            print('waiting 5 seconds')
            time.sleep(5)
            pass
    
        def task13():
            print('waiting 5 seconds')
            time.sleep(5)
            pass

        tasks = [task0, task1, task2, task3, task4, task5, task6, task7, task8, task9, task10, task11, task12, task13]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Wait for client3 to reboot (if necessary).")
        print("- Register client3 to SUSE Manager.")
        print("- Verify that the system is accessible via the WebUI Systems page.")
        print("- Discover any issues, and fix them.")
        print("- Verify that any fix remains valid after a reboot.")
    else:
        print(" ")   

def lab4(debug=False):
    lab_name = "registration lab4"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"

        def task0():
            time.sleep(1)
            pass        

        spacecmd_clear_caches = "spacecmd -u admin -p sumapass clear_caches"
        
        if debug:
            subprocess.run(spacecmd_clear_caches.split())
        else:
            with utils.shutup():
                subprocess.run(spacecmd_clear_caches.split())
        if debug:
            print("Cleared Spacewalk caches.")

        spacecmd_system_list = "spacecmd -u admin -p sumapass system_list"
        spacecmd_output = subprocess.run(spacecmd_system_list.split(), stdout=subprocess.PIPE).stdout.decode('utf-8')

        if debug:
            print("List of systems:")
            print(spacecmd_output)

        # Extract client IDs and remove 'client4' if present
        clients = re.findall(r'(client\d+)', spacecmd_output)
        if 'client4' in clients:
            clients.remove('client4')

        # Randomly select a client ID for client2copy or use 'client1' as default
        if clients:
            client2copy = random.choice(clients)
        else:
            client2copy = "client1"
        client2break = "client4"

        if debug:
            print(f"Selected {client2copy} as client2copy.")

        def task1():
            ssh_output = utils.ssh_connect(client2break, 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass
        
        def task2():
            ssh_output = utils.ssh_connect(client2copy, 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)        
            pass

        def task3():
            command = f'scp {client2copy}:/etc/machine-id /tmp/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying client2copy /etc/machine-id to local machine.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task4():
            command = f'scp -r {client2copy}:/etc/salt/* /tmp/salt/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying /etc/salt to local machine - if it exists")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task5():
            command = f'scp -r {client2copy}:/etc/venv-salt-minion/* /tmp/salt/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying /etc/venv-salt-minion/ to local machine - if it exists")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task6():
            command = f'scp /tmp/machine-id {client2break}:/etc/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying machine-id from local machine to client2break - /etc/machine-id")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task7():
            command = f'scp /tmp/machine-id {client2break}:/var/lib/dbus/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying machine-id from local machine to client2break - /var/lib/dbus/machine-id")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task8():
            command = "mkdir -p /etc/salt /etc/venv-salt-minion/"
            result = utils.ssh_connect(client2break, 'root', utils.client_password, command, debug)
            if debug:
                print(f"Creating salt client directories if needed on client1.")
                print(result)
            pass

        def task9():
            line = client2copy                
            utils.add_line_to_file(line, "/tmp/salt/minion_id", debug)
            if debug: 
                print(f"Adding line to /tmp/salt/minion_id: {line}")
            pass   

        def task10():
            command = f'scp -r /tmp/salt/* {client2break}:/etc/salt/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copy local /tmp/salt/* to client2break - /etc/salt")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task11():
            command = f'scp -r /tmp/salt/* {client2break}:/etc/venv-salt-minion/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copy local /tmp/salt/* to client2break - /etc/salt")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task12():
            command = f'rm -r /tmp/salt /tmp/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Cleanup local files - /tmp/salt/ /tmp/machine-id")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        tasks = [task0, task1, task2, task3, task4, task5, task6, task7, task8, task9, task10, task11, task12]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Register client4 to SUSE Manager.")
        print("- Wait a minute.")
        print("- Verify that all clients are accessible via the WebUI Systems page.")
    else:
        print(" ") 

"""
def full(debug=False):    
    lab_name = "registration full"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"

        def task0():
            time.sleep(1)
            pass

        def task1():
            ssh_output = utils.ssh_connect("client1", 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass

        def task2():
            command = 'rm -rf /etc/salt /etc/venv-salt-minion'
            result = utils.ssh_connect("client1", 'root', utils.client_password, command, debug)
            if debug:
                print(f"Cleaning potential salt files on client1.")
                print(result)
            pass

        def task3():
            command = "mkdir -p /etc/salt /etc/venv-salt-minion/"
            result = utils.ssh_connect("client1", 'root', utils.client_password, command, debug)
            if debug:
                print(f"Creating salt client directories if needed on client1.")
                print(result)
            pass

        def task4():
            command = "chattr +i /etc/venv-salt-minion"
            result = utils.ssh_connect("client1", 'root', utils.client_password, command, debug)
            if debug:
                print(f"Changing directory attributes for /etc/venv-salt-minion on client1.")
                print(result)
            pass    

        def task5():
            command = "chattr +i /etc/salt"
            result = utils.ssh_connect("client1", 'root', utils.client_password, command, debug)
            if debug:
                print(f"Changing directory attributes for /etc/salt on client1.")
                print(result)
            pass

        def task6():
            ssh_output = utils.ssh_connect("client2", 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass


        def task7():
            command = f'zypper in -y salt-minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 


        def task8():
            command = f'cp /etc/salt/minion /tmp/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f'Copying /etc/salt/minion on the host to /tmp/minion for file manipulation.')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task9():
            command = r"sed -i '/^#master_port: 4506/a master_port: 45506' /tmp/minion"
            result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f'Modifying the /tmp/minion file.')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task10():
            command = "mkdir -p /etc/salt /etc/venv-salt-minion/"
            result = utils.ssh_connect("client2", 'root', utils.client_password, command, debug)
            if debug:
                print(f"Creating salt client directories if needed on client1.")
                print(result)
            pass    

        def task11():
            command = f'rsync -r /tmp/minion {"client2"}:/etc/salt/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Moving /tmp/minion file to client2:/etc/salt/minion")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task12():
            command = f'rsync -r /tmp/minion {"client2"}:/etc/venv-salt-minion/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Moving /tmp/minion file to client2:/etc/venv-salt-minion/minion")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task13():
            command = f'rm -rf /tmp/minion'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Cleaning up local /tmp/minion file.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task14():
            ssh_output = utils.ssh_connect("client3", 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass


        def task15():
            command = f'cp /etc/sysconfig/proxy /tmp/proxy'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Copying /etc/sysconfig/proxy to /tmp/proxy for file manipulation.')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 

        def task16():
            pattern = r'PROXY_ENABLED=.*'
            replacement = 'PROXY_ENABLED="yes"'
            utils.modify_file_using_regex(pattern, replacement, '/tmp/proxy', debug)
            if debug:
                print('Enabling proxy in /tmp/proxy file.')
            pass        

        def task17():
            pattern = r'HTTPS_PROXY=.*'
            replacement = 'HTTPS_PROXY="192.168.0.1"'
            utils.modify_file_using_regex(pattern, replacement, '/tmp/proxy', debug)
            if debug:
                print('Setting HTTPS_PROXY in /tmp/proxy file.')
            pass

        def task18():
            line = f'export https_proxy="http://192.168.0.1"'
            utils.add_line_to_file(line, "/tmp/bashrc", debug)
            if debug: 
                print(f"Adding line to /tmp/bashrc: {line}")
            pass                

        def task19():
            command = f'scp /tmp/proxy client3:/etc/sysconfig/proxy'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Copying /tmp/proxy to client3:/etc/sysconfig/proxy')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task20():
            command = f'scp /tmp/bashrc client3:/root/.bashrc'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Copying /tmp/bashrc to client3:/root/.bashrc')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task21():
            command = f'ssh client3 reboot'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Rebooting client3')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task22():
            command = f'rm /tmp/proxy /tmp/bashrc'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print('Cleaning up local files: /tmp/proxy /tmp/.bashrc')
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 

    
        spacecmd_clear_caches = "spacecmd -u admin -p sumapass clear_caches"
        subprocess.run(spacecmd_clear_caches.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if debug:
            print("Cleared Spacewalk caches.")

        spacecmd_system_list = "spacecmd -u admin -p sumapass system_list"
        spacecmd_output = subprocess.run(spacecmd_system_list.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.decode('utf-8')

        if debug:
            print("List of systems:")
            print(spacecmd_output)

        # Extract client IDs and remove 'client4' if present
        clients = re.findall(r'(client\d+)', spacecmd_output)
        if 'client4' in clients:
            clients.remove('client4')

        # Randomly select a client ID for client2copy or use 'client1' as default
        if clients:
            client2copy = random.choice(clients)
        else:
            client2copy = "client1"

        if debug:
            print(f"Selected {client2copy} as client2copy.")

        def task23():
            ssh_output = utils.ssh_connect("client4", 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)
            pass
        
        def task24():
            ssh_output = utils.ssh_connect("client4", 'root', None, 'echo SSH_OK', debug)
            if ssh_output is None:
                print("Unable to establish a passwordless SSH connection to the client.")
                print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                print("Refer to the provided documentation for further guidance.")
                sys.exit(1)        
            pass

        def task25():
            command = f'scp client4:/etc/machine-id /tmp/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying client2copy /etc/machine-id to local machine.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task26():
            command = f'scp -r client4:/etc/salt/* /tmp/salt/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying /etc/salt to local machine - if it exists")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task27():
            command = f'scp -r client4:/etc/venv-salt-minion/* /tmp/salt/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying /etc/venv-salt-minion/ to local machine - if it exists")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task28():
            command = f'scp /tmp/machine-id client4:/etc/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying machine-id from local machine to client2break - /etc/machine-id")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task29():
            command = f'scp /tmp/machine-id client4:/var/lib/dbus/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copying machine-id from local machine to client2break - /var/lib/dbus/machine-id")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task30():
            command = "mkdir -p /etc/salt /etc/venv-salt-minion/"
            result = utils.ssh_connect("client4", 'root', utils.client_password, command, debug)
            if debug:
                print(f"Creating salt client directories if needed on client1.")
                print(result)
            pass

        def task31():
            line = client2copy                
            utils.add_line_to_file(line, "/tmp/salt/minion_id", debug)
            if debug: 
                print(f"Adding line to /tmp/salt/minion_id: {line}")
            pass   

        def task32():
            command = f'scp -r /tmp/salt/* client4:/etc/salt/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copy local /tmp/salt/* to client2break - /etc/salt")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task33():
            command = f'scp -r /tmp/salt/* client4:/etc/venv-salt-minion/'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Copy local /tmp/salt/* to client2break - /etc/salt")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task34():
            command = f'rm -r /tmp/salt /tmp/machine-id'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Cleanup local files - /tmp/salt/ /tmp/machine-id")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass    

        tasks = [task0, task1, task2, task3, task4, task5, task6, task7, task8, task9, task10, task11, task12, task13, task14, task15,
                 task16, task17, task18, task19, task20, task21, task22, task23, task24, task25, task26, task27, task28, task29, task30, 
                 task31, task32, task33, task34]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Register all clients to SUSE Manager")
        print("- Verify that all clients are accessible via the WebUI Systems page.")
    else:
        print(" ")
    """    
      

"""
Cleanup commands, one-liner:
# rm -rf /etc/venv-salt-minion/* /var/cache/venv-salt-minion/* /etc/zypp/{credentials,services,repos}.d/*; zypper rm -y venv-salt-minion

def reset(debug=False):
    lab_name = "registration reset"
    if utils.query_yes_no("About to reset all registration labs.\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"

        with utils.alive_bar(unknown=utils.bar_theme) as bar:

            # Run the commands on the host server
            spacecmd_clear_caches = "spacecmd -u admin -p sumapass clear_caches"
            subprocess.run(spacecmd_clear_caches.split())
            if debug:
                print("Cleared Spacewalk caches.")

            for sid in range(1, 17):
                spacecmd_delete_system = f"spacecmd -u admin -p sumapass api -- system.deleteSystem -A 10000100{sid:02d}"
                subprocess.run(spacecmd_delete_system.split())

            # Loop through the clients
            for client_num in range(1, 5):
                client = f"client{client_num}"

                # Check SSH connection
                ssh_output = utils.ssh_connect(client, 'root', None, 'echo SSH_OK', debug)
                if ssh_output is None:
                    print(f"Unable to establish a passwordless SSH connection to {client}.")
                    print("Please ensure the client is set up for key-based authentication and verify the connection manually.")
                    print("Refer to the provided documentation for further guidance.")
                    sys.exit(1)

                # Run commands on the client
                commands = [
                    "zypper rm -y salt-minion venv-salt-minion python3-salt salt",
                    "rm -rf /etc/salt/* /etc/venv-salt-minion/*",
                    "rm -rf /etc/zypp{credentials,services,repos}.d/*",
                    "rm /root/.bashrc",
                    "rm /etc/machine-id",
                    "rm /var/lib/dbus/machine-id",
                    "dbus-uuidgen --ensure",
                    "systemd-machine-id-setup"
                ]

                if client_num == 3:
                    commands.append("reboot")

                for cmd in commands:
                    result = utils.ssh_connect(client, 'root', utils.client_password, cmd, debug)
                    if debug:
                        print(f"Executing command on {client}: {cmd}")
                        print(result)

                # Modify /tmp/proxy file
                pattern = r'PROXY_ENABLED=.*'
                replacement = 'PROXY_ENABLED=""'
                utils.modify_file_using_regex(pattern, replacement, '/tmp/proxy', debug)

            spacecmd_clear_caches = "spacecmd -u admin -p sumapass clear_caches"        

            print(lab_name + " - [Reset Complete]") 
    else:
        print(" ")   
"""             


def registration(args, debug=False):
    if args.lab1:
        lab1(debug)
    elif args.lab2:
        lab2(debug) 
    elif args.lab3:
        lab3(debug) 
    elif args.lab4:
        lab4(debug)
#    elif args.full:
#        full(debug)
#    elif args.reset:
#        reset(debug)    