#! /usr/bin/python3.6

import warnings
warnings.filterwarnings(action='ignore',message='Python 3.6 is no longer supported')
import os
os.environ['PYTHONIOENCODING'] = 'UTF-8'
os.environ['LANG'] = 'en_US.UTF-8'
import argparse
import sys
from mgrsync import mgrsync
from patching import patching
from registration import registration
import paramiko
#from upgrading import upgrading

def main(argv):
    try:
        parser = argparse.ArgumentParser(description="SUSE Manager Training Lab Scenarios")
        
        # Hidden debug argument
        parser.add_argument('--debug', action='store_true', help=argparse.SUPPRESS)

        subparsers = parser.add_subparsers(dest='command', help='Available commands')

        # mgr-sync lab scenarios
        parser_mgr_sync = subparsers.add_parser('mgr-sync', help='mgr-sync lab scenarios.')
        parser_mgr_sync.add_argument('--lab1', action='store_true', help='Load the lab1 scenario')
        parser_mgr_sync.add_argument('--lab2', action='store_true', help='Load the lab2 scenario')
        parser_mgr_sync.add_argument('--lab3', action='store_true', help='Load the lab3 scenario')
        parser_mgr_sync.add_argument('--lab4', action='store_true', help='Load the lab4 scenario')    
        parser_mgr_sync.add_argument('--full', action='store_true', help='Load all of the mgr-sync scenarios')
        parser_mgr_sync.add_argument('--reset', action='store_true', help='Reset the mgr-sync lab scenarios')

        # registration lab scenarios
        parser_mgr_sync = subparsers.add_parser('registration', help='registration lab scenarios.')
        parser_mgr_sync.add_argument('--lab1', action='store_true', help='Load the lab1 scenario')
        parser_mgr_sync.add_argument('--lab2', action='store_true', help='Load the lab2 scenario')
        parser_mgr_sync.add_argument('--lab3', action='store_true', help='Load the lab3 scenario')
        parser_mgr_sync.add_argument('--lab4', action='store_true', help='Load the lab4 scenario')    
        #parser_mgr_sync.add_argument('--full', action='store_true', help='Load all of the registration lab scenarios') 
        #parser_mgr_sync.add_argument('--reset', action='store_true', help='Reset the registration lab scenarios')


        # patching lab scenarios
        parser_mgr_sync = subparsers.add_parser('patching', help='patching lab scenarios.')
        parser_mgr_sync.add_argument('--lab1', action='store_true', help='Load the lab1 scenario')
        parser_mgr_sync.add_argument('--lab2', action='store_true', help='Load the lab2 scenario')
        parser_mgr_sync.add_argument('--lab3', action='store_true', help='Load the lab3 scenario')
        parser_mgr_sync.add_argument('--lab4', action='store_true', help='Load the lab4 scenario')    
        parser_mgr_sync.add_argument('--full', action='store_true', help='Load all of the patching lab scenarios')   
        parser_mgr_sync.add_argument('--reset', action='store_true', help='Reset the patching lab scenarios')

        # upgrading lab scenarios
        #parser_mgr_sync = subparsers.add_parser('upgrading', help='upgrading lab scenarios.')
        #parser_mgr_sync.add_argument('--lab1', action='store_true', help='Load the lab1 scenario')
        #parser_mgr_sync.add_argument('--lab2', action='store_true', help='Load the lab2 scenario')
        #parser_mgr_sync.add_argument('--lab3', action='store_true', help='Load the lab3 scenario')
        #parser_mgr_sync.add_argument('--lab4', action='store_true', help='Load the lab4 scenario')    
        #parser_mgr_sync.add_argument('--full', action='store_true', help='Load all of the upgrading lab scenarios')   
        #parser_mgr_sync.add_argument('--reset', action='store_true', help='Reset the upgrading lab scenarios')

        if len(argv) == 0:
            parser.print_help()
        else:
            args = parser.parse_args(argv)
            if args.command == 'mgr-sync':
                mgrsync(args, args.debug)
            elif args.command == 'registration':
                registration(args, args.debug)
            elif args.command == 'patching':
                patching(args, args.debug)
            #elif args.command == 'upgrading':
            #    upgrading(args, args.debug)  
    except KeyboardInterrupt:
        print("\nExecution interrupted by user. Exiting...")
        sys.exit(1)

if __name__ == '__main__':
    main(sys.argv[1:])