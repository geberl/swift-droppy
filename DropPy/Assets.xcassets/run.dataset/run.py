#!/usr/bin/python
# -*- coding: utf-8 -*-

import argparse
import importlib
import json
import os
import sys


TASK_SUBFOLDER_IN_WORKSPACE = "Tasks"
WORKFLOW_SUBFOLDER_IN_WORKSPACE = "Workflows"
TASK_PYTHON_FILE_NO_EXT = "task"
TASK_CLASS_NAME = "Task"


class Run(object):
    def __init__(self, workspace_path, workflow_name, input_path, output_path):
        workflow_dict = self.read_workflow_json(workspace_path, workflow_name)

        task_name, kwargs_dict = self.get_task_info(output_path, workflow_dict)

        input_paths = self.get_input_files(input_path)

        self.instantiate_and_execute(workspace_path, task_name,
                                     input_paths, output_path, kwargs_dict)

    @staticmethod
    def read_workflow_json(workspace_path, workflow_name):
        workflow_path = os.path.join(workspace_path,
                                     WORKFLOW_SUBFOLDER_IN_WORKSPACE,
                                     workflow_name)

        with open(workflow_path, 'r') as file_handler:
            workflow_dict = json.loads(file_handler.read())

        return workflow_dict

    @classmethod
    def get_task_info(cls, output_path, workflow_dict):
        task_id = os.path.basename(output_path)
        step_abs, splitter_path_abs = cls.get_basic_info(task_id)
        task_name, kwargs_dict = cls.traverse_queue(workflow_dict['queue'],
                                                    step_abs,
                                                    splitter_path_abs)
        return task_name, kwargs_dict

    @staticmethod
    def get_basic_info(task_id_string):
        task_list = task_id_string.split('-')
        step = int(task_list[0])

        if len(task_list) > 0:
            splitters = task_list[1:]
        else:
            splitters = []

        return step, splitters

    @staticmethod
    def get_task_info_from_queue(queue_dict, queue_rel_step):
        task = queue_dict[queue_rel_step - 1]['task']
        if 'kwargs' in queue_dict[queue_rel_step - 1]:
            kwargs = queue_dict[queue_rel_step - 1]['kwargs']
        else:
            kwargs = {}
        return task, kwargs

    @classmethod
    def traverse_queue(cls, remaining_queue, step_rel, remaining_splitter_path):
        if 'splitter' in remaining_queue[-1]:
            if len(remaining_queue) <= step_rel:
                path_to_take = remaining_splitter_path[0]

                splitter_queue = remaining_queue[-1]['splitter'][path_to_take]
                splitter_steps = step_rel - (len(remaining_queue) - 1)
                splitter_path = remaining_splitter_path[1:]

                task, kwargs = cls.traverse_queue(splitter_queue,
                                                  splitter_steps,
                                                  splitter_path)
            else:
                task, kwargs = cls.get_task_info_from_queue(remaining_queue,
                                                            step_rel)
        else:
            task, kwargs = cls.get_task_info_from_queue(remaining_queue,
                                                        step_rel)

        return task, kwargs

    @staticmethod
    def get_input_files(input_path):
        input_files = os.listdir(input_path)
        input_paths = [os.path.join(input_path, input_file) for input_file in
                       input_files]
        return input_paths

    @staticmethod
    def instantiate_and_execute(workspace_path, task_name, input_paths,
                                output_path, kwargs_dict):
        try:
            task_dir = os.path.join(workspace_path,
                                    TASK_SUBFOLDER_IN_WORKSPACE,
                                    task_name)
            sys.path.insert(0, task_dir)

            task_module = importlib.import_module(TASK_PYTHON_FILE_NO_EXT)
            task_class = getattr(task_module, TASK_CLASS_NAME)
            task_class(input_paths, output_path, **kwargs_dict)
            sys.exit(0)
        except Exception as err:
            print(err)
            sys.exit(1)


def parse_arguments():
    """
    Ensured preconditions:
    - All passed directories and files exist.
    - The Workflow json file includes all used parameters.
    - The input_path directory contains at least one file.
    - The output_path directory is empty.
    """

    parser = argparse.ArgumentParser()
    required_named = parser.add_argument_group('required named arguments')
    required_named.add_argument('-w',
                                '--workspace',
                                type=unicode,
                                help='absolute path to DropPy workspace',
                                action='store',
                                required=True)
    required_named.add_argument('-j',
                                '--json',
                                type=unicode,
                                help='name of selected Workflow json file',
                                action='store',
                                required=True)
    required_named.add_argument('-i',
                                '--input',
                                type=unicode,
                                help='absolute path to the input directory',
                                action='store',
                                required=True)
    required_named.add_argument('-o',
                                '--output',
                                type=unicode,
                                help='absolute path to the output directory',
                                action='store',
                                required=True)
    parser.add_argument('-v',
                        '--version',
                        help='display version info and exit',
                        action='store_true')

    return parser.parse_args()


def print_version():
    print('Version 2, 2017-09-06')
    sys.exit(0)


if __name__ == '__main__':
    args = parse_arguments()

    if args.version:
        print_version()
    else:
        r = Run(args.workspace, args.json, args.input, args.output)
