import os
import utils
import time
import subprocess
import sys

def lab1(debug=False):
    lab_name = "patching lab1"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]\n"
        client2break = "client1"
        channel2remove = "sle-product-sles15-sp3-ltss-updates-x86_64"

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
            command = f"spacecmd -u admin -p sumapass -y -- system_removechildchannels {client2break} {channel2remove}"
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Running spacecmd to remove the childchannel {channel2remove} from {client2break}")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 

        def task3():
            time.sleep(1)
            pass

        tasks = [task0, task1, task2, task3]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Apply Patches to client1.")
        print("- Verify that the patches install successfully.")
        print("- Verify that the system is running the latest LTSS kernel.")
    else:
        print(" ") 

def lab2(debug=False):
    lab_name = "patching lab2"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]\n"
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
            command = f'ssh {client2break} zypper al kernel*'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Adding a zypper lock to the kernel on {client2break}")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 

        def task3():
            time.sleep(1)
            pass

        tasks = [task0, task1, task2, task3]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Apply Patches to client2.")
        print("- Verify that the patches install successfully.")
        print("- Verify that the system is running the latest LTSS kernel.")
    else:
        print(" ")     

def lab3(debug=False):
    lab_name = "patching lab3"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]\n"
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
            subcommand = f"nohup bash -c 'exec -a zypper sleep 1000000' >/dev/null 2>&1 &"
            command = ['ssh', client2break, subcommand]
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(f"Running a sleep command, disguised as zypper on {client2break}")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task3():
            subcommand = f"pgrep -f zypper > /var/run/zypp.pid"
            command = ['ssh', client2break, subcommand ]
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Writing zypper process ID(s) to /var/run/zypp.pid.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass  

        def task4():
            time.sleep(1)
            pass

        tasks = [task0, task1, task2, task3, task4]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Apply Patches to client3.")
        print("- Verify that the patches install successfully.")
        print("- Verify that the system is running the latest LTSS kernel.")
    else:
        print(" ")      

def lab4(debug=False):
    lab_name = "patching lab4"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]\n"

        def task0():
            time.sleep(1)
            pass

        def task1():
            command = f'zypper in -y --oldpackage salt-master-3002.2-150300.53.7.2 salt-3002.2-150300.53.7.2 python3-salt-3002.2-150300.53.7.2 salt-api-3002.2-150300.53.7.2 salt-bash-completion-3002.2-150300.53.7.2 salt-minion-3002.2-150300.53.7.2.x86_64'
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Reverting salt to old package versions.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task2():
            time.sleep(1)
            pass

        def task3():
            print("\n Please wait. This may take a minute.")
            command = f"spacewalk-service restart"
            result = subprocess.run(command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print("Restarting spacewalk-service.")
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass 

        def task4():
            time.sleep(1)
            pass

        tasks = [task0, task1, task2, task3, task4]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Apply Patches to client4.")
        print("- Verify that the patches install successfully.")
        print("- Verify that the system is running the latest LTSS kernel.")
    else:
        print(" ")    

def patching(args, debug=False):
    if args.lab1:
        lab1(debug)
    elif args.lab2:
        lab2(debug) 
    elif args.lab3:
        lab3(debug) 
    elif args.lab4:
        lab4(debug) 
   # elif args.full:
   #     full(debug)
   # elif args.reset:
   #     reset(debug)                      
