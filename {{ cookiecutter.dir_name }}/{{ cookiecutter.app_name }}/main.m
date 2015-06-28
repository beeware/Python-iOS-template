//
//  main.m
//  A main module for starting Python projects under iOS.
//
//  Copyright (c) 2014 Russell Keith-Magee.
//  Released under the terms of the BSD license.
//  Copyright (c) 2014 Russell Keith-Magee.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <Python/Python.h>
#include <dlfcn.h>

int main(int argc, char *argv[]) {
    int ret = 0;
    unsigned int i;
    NSString *python_path;
    wchar_t* python_home;
    wchar_t** python_argv;

    @autoreleasepool {
        NSString * resourcePath = [[NSBundle mainBundle] resourcePath];

        // Special environment to prefer .pyo, and don't write bytecode if .py are found
        // because the process will not have write attribute on the device.
        putenv("PYTHONOPTIMIZE=2");
        putenv("PYTHONDONTWRITEBYTECODE=1");
        putenv("PYTHONNOUSERSITE=1");

        python_path = [NSString stringWithFormat:@"PYTHONPATH=%@/app:%@/app_packages",
                       resourcePath, resourcePath, nil];
        NSLog(@"%s", [python_path UTF8String]);
        putenv((char *)[python_path UTF8String]);

        NSLog(@"PythonHome is: %s", [resourcePath UTF8String]);
        python_home = _Py_char2wchar([resourcePath cStringUsingEncoding:NSUTF8StringEncoding], NULL);
        Py_SetPythonHome(python_home);

        NSLog(@"Initializing Python runtime");
        Py_Initialize();

        python_argv = PyMem_RawMalloc(sizeof(wchar_t*) * argc);
        const char* main_script = [
            [[NSBundle mainBundle] pathForResource:@"app/{{ cookiecutter.app_name }}/main"
                                            ofType:@"py"] cStringUsingEncoding:NSUTF8StringEncoding];

        python_argv[0] = _Py_char2wchar(main_script, NULL);
        for (i = 1; i < argc; i++) {
            python_argv[i] = _Py_char2wchar(argv[i], NULL);
        }

        PySys_SetArgv(argc, python_argv);

        // If other modules are using threads, we need to initialize them.
        PyEval_InitThreads();

        // Start main.py
        NSLog(@"Running %s", main_script);
        FILE* fd = fopen(main_script, "r");
        if (fd == NULL)
        {
            ret = 1;
            NSLog(@"Unable to open main.py, abort.");
        }
        else
        {
            ret = PyRun_SimpleFileEx(fd, main_script, 1);
            if (ret != 0)
            {
                NSLog(@"Application quit abnormally!");
            }
        }

        @try
        {
            // Start the Python app
            UIApplicationMain(0, NULL, NULL, @"PythonAppDelegate");
        }
        @catch (NSException *exception)
        {
            NSLog(@"Error running Python application: %@", exception.reason);
        }

        Py_Finalize();
        NSLog(@"Leaving");
    }

    exit(ret);
    return ret;
}
