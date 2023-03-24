import os
import utils
import time
import socket
import subprocess
import yaml
import sys

def lab1(debug=False):
    lab_name = "mgr-sync lab1"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'): 
        print("")
        bar_title= lab_name + " - [Loading]\n"
        line1 = "8.8.8.8    scc.suse.com        scc"
        line2 = "8.8.4.4    updates.suse.com    updates"

        def task1():
            time.sleep(1)
            pass

        def task2():    
            if debug:
                print("Current content of /etc/hosts before adding lines:")
                with open("/etc/hosts", "r") as f:
                    print(f.read())
            pass

        def task3():
            utils.add_line_to_file(line1, "/etc/hosts", debug)
            if debug: 
                print(f"Adding line to /etc/hosts: {line1}")
            pass

        def task4():
            utils.add_line_to_file(line2, "/etc/hosts", debug)
            if debug:
                print(f"Adding line to /etc/hosts: {line2}\n\n")
            pass

        tasks = [task1,task2,task3,task4]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Go to the SUSE Manager WebUI.")
        print("- Navigate to SUSEManager>Admin>Setup Wizard>Products")
        print("- Select the 'refresh' button to 'Refresh the product catalog from the SUSE Customer Center'.")
        print("- Discover any issues, and fix them.")
    else:
        print(" ")

def lab2(debug=False):
    lab_name = "mgr-sync lab2"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title= lab_name + " - [Loading]\n"

        def task1():
            time.sleep(1)
            result = subprocess.run(["systemctl", "start", "firewalld"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task2():
                # check currect rules
            if debug:
                print("Firewalld status before reloading:")
                result_before = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--get-all-rules"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(result_before.stdout.decode('utf-8'))
            pass    

        def task3():
            # Get the IP addresses for scc.suse.com
            dig_out_result = subprocess.run(["dig", "+short", "scc.suse.com"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            dig_out = dig_out_result.stdout.decode('utf-8').strip().split("\n")

            for ip in dig_out:
                # Add a rich rule to block traffic to the IP addresses of scc.suse.com
                if debug:
                    print(f"Blocking IP: {ip}")
                result = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--add-rule", "ipv4", "filter", "OUTPUT", "0", "-d", ip, "-j", "REJECT"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if debug:
                    print(result.stdout.decode('utf-8'))
                    print(result.stderr.decode('utf-8'))
            pass

        def task4():
            # Check rules and reload
            subprocess.run(["firewall-cmd", "--reload"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

            if debug:
                print("Firewalld status after reloading:")
                result_before = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--get-all-rules"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(result_before.stdout.decode('utf-8'))
            pass
        
        tasks = [task1,task2,task3,task4]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Go to the SUSE Manager WebUI.")
        print("- Refresh the product catalog from the SUSE Customer Center.")
        print("- Discover any issues, and fix them.")
    else:
        print(" ")

def lab3(debug=False):
    lab_name = "mgr-sync lab3"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]"

        config = utils.load_yaml_config("/usr/share/rhn/sumalabs/conf.yaml")
        if config is None:
            print("Error loading configuration. Exiting.")
            return

        sccorguser = config["sccorguser"]

        def task1():
            time.sleep(1)
            pass  

        def task2():
            result = subprocess.run(["iptables", "-S"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            output = result.stdout.decode('utf-8')
            if debug:
                print(output)

            if "OUTPUT" in output and "REJECT" in output:
                print("Warning: Resolve the 'mgr-sync lab2' scenario. Or run `sumalabs mgr-sync --reset' and try again.")
                sys.exit()

        def task3():
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", sccorguser, "sync.content.deleteCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        tasks = [task1, task2, task3]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Go to the SUSE Manager WebUI.")
        print("- Navigate to SUSEManager>Admin>Setup Wizard>Products")
        print("- Attempt to mirror a child product from SLES 15 SP3 in the webUI.")
        print("- Discover any issues, and fix them.")
    else:
        print(" ")

def lab4(debug=False):
    lab_name = "mgr-sync lab4"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]"

        config = utils.load_yaml_config("/usr/share/rhn/sumalabs/conf.yaml")
        if config is None:
            print("Error loading configuration. Exiting.")
            return

        sccorguser = config["sccorguser"]
        sccemptyuser = config["sccemptyuser"]
        sccemptypass = config["sccemptypass"]

        def task1():
            time.sleep(1)
            pass

        def task2():
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", sccorguser, "sync.content.deleteCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task3():
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", f"{sccemptyuser},{sccemptypass},true", "sync.content.addCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        tasks = [task1, task2, task3]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Go to the SUSE Manager WebUI.")
        print("- Run 'mgr-sync refresh', or refresh product catalog in the webUI.")
        print("- Attempt to mirror a child product from SLES 15 SP3 in the webUI.")
        print("- Discover any issues, and fix them.")
    else:
        print(" ")


def full(debug=False):
    lab_name = "mgr-sync full"
    if utils.query_yes_no("About to execute the scenario: " + lab_name + "\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]"
        line1 = "8.8.8.8    scc.suse.com        scc"
        line2 = "8.8.4.4    updates.suse.com    updates"

        config = utils.load_yaml_config("/usr/share/rhn/sumalabs/conf.yaml")
        if config is None:
            print("Error loading configuration. Exiting.")
            return

        sccorguser = config["sccorguser"]
        sccemptyuser = config["sccemptyuser"]
        sccemptypass = config["sccemptypass"]

        def task1():
            time.sleep(1)
            pass

        def task2():    
            if debug:
                print("Current content of /etc/hosts before adding lines:")
                with open("/etc/hosts", "r") as f:
                    print(f.read())
            pass

        def task3():
            utils.add_line_to_file(line1, "/etc/hosts", debug)
            if debug: 
                print(f"Adding line to /etc/hosts: {line1}")
            pass

        def task4():
            utils.add_line_to_file(line2, "/etc/hosts", debug)
            if debug:
                print(f"Adding line to /etc/hosts: {line2}\n\n")
            pass

        def task5():
            time.sleep(1)
            result = subprocess.run(["systemctl", "start", "firewalld"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task6():
            if debug:
                print("Firewalld status before reloading:")
                result_before = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--get-all-rules"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(result_before.stdout.decode('utf-8'))
            pass    

        def task7():
            dig_out_result = subprocess.run(["dig", "+short", "scc.suse.com"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            dig_out = dig_out_result.stdout.decode('utf-8').strip().split("\n")

            for ip in dig_out:
                if debug:
                    print(f"Blocking IP: {ip}")
                result = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--add-rule", "ipv4", "filter", "OUTPUT", "0", "-d", ip, "-j", "REJECT"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                if debug:
                    print(result.stdout.decode('utf-8'))
                    print(result.stderr.decode('utf-8'))
            pass

        def task8():
            subprocess.run(["firewall-cmd", "--reload"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)

            if debug:
                print("Firewalld status after reloading:")
                result_before = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--get-all-rules"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                print(result_before.stdout.decode('utf-8'))
            pass

        def task9():
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", sccorguser, "sync.content.deleteCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task10():
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", f"{sccemptyuser},{sccemptypass},true", "sync.content.addCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass
    
        tasks = [task1, task2, task3, task4, task5, task6, task7, task8, task9, task10]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nInstructions:")
        print("- Go to the SUSE Manager WebUI.")
        print("- Refresh the product catalog from the SUSE Customer Center.")
        print("- Run 'mgr-sync refresh', or refresh the product catalog in the webUI.")
        print("- Attempt to mirror a child product from SLES 15 SP3 in the webUI.")
        print("- Discover issues, and fix them.")
    else:
        print(" ")  

def reset(debug=False):
    lab_name = "mgr-sync reset"
    if utils.query_yes_no("About to reset all changes made by mgr-sync labs.\nDo you want to proceed?", default='no'):
        print("")
        bar_title = lab_name + " - [Loading]"

        config = utils.load_yaml_config("/usr/share/rhn/sumalabs/conf.yaml")
        if config is None:
            print("Error loading configuration. Exiting.")
            return    
        
        sccorguser = config["sccorguser"]
        sccorgpass = config["sccorgpass"]
        sccemptyuser = config["sccemptyuser"]

        def task1():
            time.sleep(1)
            pass

        def task2():
            # Lab 1 reset
            if debug:
                print("Current content of /etc/hosts before removing lines:")
                with open("/etc/hosts", "r") as f:
                    print(f.read())
            partial_line1 = "scc"
            partial_line2 = "updates"      
            utils.remove_line_from_file(partial_line1, "/etc/hosts", debug)
            utils.remove_line_from_file(partial_line2, "/etc/hosts", debug)
            pass

        def task3():
            # lab 2 reset
            if debug:
                print(f"Removing Firewall OUTPUT Direct Rules (Permanently)")
            result = subprocess.run(["firewall-cmd", "--permanent", "--direct", "--remove-rules", "ipv4", "filter", "OUTPUT"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug: 
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task4():
            # lab2 reset continued
            result = subprocess.run(["systemctl", "stop", "firewalld"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task5():
            # lab2 reset continued
            result = subprocess.run(["firewall-cmd", "--reload"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        def task6():
            # lab 3 and 4 reset
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", sccemptyuser, "sync.content.deleteCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass    

        def task7():
            # lab 3 and 4 reset continued
            result = subprocess.run(["spacecmd", "-u", "admin", "-p", "sumapass", "api", "--", "-A", f"{sccorguser},{sccorgpass},true", "sync.content.addCredentials"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if debug:
                print(result.stdout.decode('utf-8'))
                print(result.stderr.decode('utf-8'))
            pass

        tasks = [task1, task2, task3, task4, task5, task6, task7]
        utils.create_alive_bar(bar_title, tasks)

        print(lab_name + " - [Ready]")
        print("\nReset complete!")
    else:
        print(" ")      

def mgrsync(args, debug=False):
    if args.lab1:
        lab1(debug)
    elif args.lab2:
        lab2(debug)
    elif args.lab3:
        lab3(debug)
    elif args.lab4:
        lab4(debug)
    elif args.full:
        full(debug)
    elif args.reset:
        reset(debug)                          