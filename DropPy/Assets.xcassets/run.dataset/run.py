#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import unicode_literals
import argparse
import importlib
import json
import os
import six
import sys
import traceback


TASK_SUBFOLDER_IN_WORKSPACE = "Tasks"
WORKFLOW_SUBFOLDER_IN_WORKSPACE = "Workflows"
TASK_PYTHON_FILE_NO_EXT = "task"
TASK_CLASS_NAME = "Task"


class Run(object):
    def __init__(self, workspace_path, workflow_name, input_path, output_path):
        workflow_dict = self.read_workflow_json(workspace_path, workflow_name)
        task_name, kwargs_dict = self.get_task_info(output_path, workflow_dict)
        input_paths = self.get_input_paths(input_path)
        self.instantiate_and_execute(workspace_path, task_name, input_paths, output_path, kwargs_dict)

    @staticmethod
    def read_workflow_json(workspace_path, workflow_name):
        workflow_path = os.path.join(workspace_path, WORKFLOW_SUBFOLDER_IN_WORKSPACE, workflow_name)
        with open(workflow_path, str('r')) as file_handler:
            workflow_dict = json.loads(file_handler.read())
        return workflow_dict

    @classmethod
    def get_task_info(cls, output_path, workflow_dict):
        task_number = int(os.path.basename(output_path))
        task_name = workflow_dict['queue'][task_number - 1]['task']
        if 'kwargs' in workflow_dict['queue'][task_number - 1]:
            kwargs_dict = workflow_dict['queue'][task_number - 1]['kwargs']
        else:
            kwargs_dict = {}
        return task_name, kwargs_dict

    @staticmethod
    def get_input_paths(input_dir):
        input_files = os.listdir(input_dir)
        input_paths = [os.path.join(input_dir, input_file) for input_file in input_files]
        return input_paths

    @staticmethod
    def instantiate_and_execute(workspace_path, task_name, input_paths, output_path, kwargs_dict):
        try:
            task_dir = os.path.join(workspace_path, TASK_SUBFOLDER_IN_WORKSPACE, task_name)
            sys.path.insert(0, task_dir)
            task_module = importlib.import_module(TASK_PYTHON_FILE_NO_EXT)
            task_class = getattr(task_module, TASK_CLASS_NAME)
            task_class(input_paths, output_path, **kwargs_dict)
            sys.exit(0)
        except Exception as err:
            print(err)
            traceback.print_exc()
            sys.exit(1)


def commandline_type(byte_string, encoding=sys.stdin.encoding):
    # Source: https://stackoverflow.com/a/33812744
    if six.PY2:
        unicode_string = byte_string.decode(encoding)
    else:  # if six.PY3:
        unicode_string = str(byte_string)
    return unicode_string


def parse_arguments():
    """
    Ensured preconditions:
    - All passed directories and files exist.
    - The Workflow json file includes all used elements.
    - The input_path directory contains at least one file.
    - The output_path directory is empty.
    """
    parser = argparse.ArgumentParser()
    required_named = parser.add_argument_group('required named arguments')
    required_named.add_argument('-w', '--workspace',
                                help='absolute path to DropPy workspace',
                                action='store',
                                type=commandline_type,
                                required=True)
    required_named.add_argument('-j', '--json',
                                help='name of selected Workflow json file',
                                action='store',
                                type=commandline_type,
                                required=True)
    required_named.add_argument('-i', '--input',
                                help='absolute path to the input directory',
                                action='store',
                                type=commandline_type,
                                required=True)
    required_named.add_argument('-o', '--output',
                                help='absolute path to the output directory',
                                action='store',
                                type=commandline_type,
                                required=True)
    parser.add_argument('-v', '--version',
                        help='display version info and exit',
                        action='store_true')
    return parser.parse_args()


def print_version():
    print('Version 5, 2017-11-03')
    sys.exit(0)


if __name__ == '__main__':
    args = parse_arguments()
    if args.version:
        print_version()
    else:
        r = Run(args.workspace, args.json, args.input, args.output)
